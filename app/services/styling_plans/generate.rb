module StylingPlans
  class Generate
    DIVERSITY_PENALTY = 8
    PRIORITIES = { "essential" => 0, "recommended" => 1, "optional" => 2 }.freeze

    class << self
      def call(user:, attributes:)
        values = attributes.to_h.symbolize_keys
        interpretation = PromptInterpreter.call(user: user, attributes: values)
        dates = dates_for(interpretation)
        plan = user.styling_plans.create!(
          plan_type: interpretation.plan_type,
          city: interpretation.city,
          country_code: user.country_code,
          start_date: dates.first,
          end_date: dates.last,
          prompt: values[:prompt]
        )
        generate!(plan)
      rescue StandardError => error
        plan&.update_columns(status: "failed", failure_code: error.class.name.demodulize.underscore, updated_at: Time.current)
        raise
      end

      private

      def dates_for(interpretation)
        start_on = interpretation.start_date
        end_on = interpretation.end_date
        days = (end_on - start_on).to_i + 1
        raise InvalidDateRangeError unless days.between?(1, StylingPlan::MAX_DAYS)

        (start_on..end_on).to_a
      end

      def generate!(plan)
        external = ExternalContext::Fetch.call(
          user: plan.user,
          city: plan.city,
          start_date: plan.start_date,
          end_date: plan.end_date
        )
        weather_by_date = external.weather.index_by { |day| day["date"] }
        selected_counts = Hash.new(0)
        suggestions = []

        StylingPlan.transaction do
          (plan.start_date..plan.end_date).each do |date|
            weather = weather_by_date[date.iso8601] || {}
            context = context_for(plan, date, weather)
            outfit, daily_suggestions = create_daily_outfit(plan, date, context, weather, selected_counts)
            suggestions.concat(daily_suggestions)
            plan.entries.create!(
              outfit: outfit,
              planned_for: date,
              context: context,
              weather_context: weather
            )
          end

          plan.update!(
            status: :completed,
            city: external.city,
            weather_context: external.weather,
            packing_summary: packing_summary(plan, selected_counts, suggestions),
            completed_at: Time.current
          )
        end
        plan
      end

      def context_for(plan, date, weather)
        default_prompt = plan.prompt.presence || I18n.t("styling_plans.default_prompt.#{plan.plan_type}")
        prompt = itinerary_for(default_prompt, date) || default_prompt
        extracted = Stylist::ExtractContext.call(prompt, timezone: plan.user.timezone)
        extracted.attributes.merge(
          "city" => plan.city,
          "itinerary" => (prompt if prompt != default_prompt),
          "planned_for" => date.iso8601,
          "season" => extracted.attributes["season"] || inferred_season(weather),
          "weather" => weather
        ).compact
      end

      def itinerary_for(prompt, date)
        day_name = Date::DAYNAMES.fetch(date.wday)
        day_first = prompt.match(/\b#{Regexp.escape(day_name)}\b\s*(?:morning|afternoon|evening)?\s*(?::|-|is|for)?\s*([^,;.]+)/i)
        return day_first[1].squish if day_first&.[](1).present?

        activity_first = prompt.match(/(?:\A|[,;.])\s*([^,;.]+?)\s+on\s+#{Regexp.escape(day_name)}\b/i)
        activity_first&.[](1)&.squish
      end

      def inferred_season(weather)
        minimum = weather["apparent_temperature_min_c"]
        maximum = weather["apparent_temperature_max_c"]
        return "winter" if minimum.present? && minimum.to_f < 8
        return "summer" if maximum.present? && maximum.to_f >= 24

        nil
      end

      def create_daily_outfit(plan, date, context, weather, selected_counts)
        candidates = Stylist::CandidateSelector.call(user: plan.user, context: context)
        personalization = Personalization::Snapshot.call(user: plan.user, as_of: date)
        scored = Stylist::CombinationBuilder.call(candidates: candidates, context: context).map do |combination|
          Stylist::CompatibilityScorer.call(
            combination: combination,
            context: context,
            style_profile: plan.user.style_profile,
            personalization: personalization
          )
        end
        selected = scored.max_by do |combination|
          combination.score - combination.items.values.sum { |item| selected_counts[item.id] * DIVERSITY_PENALTY }
        end
        raise Stylist::InsufficientWardrobeError.new([], required_combinations: OutfitTaxonomy.base_combinations) if selected.blank?

        outfit = persist_outfit(plan, date, context, weather, selected)
        suggestions = Stylist::WardrobeSuggestions.call(
          candidates: candidates,
          context: context,
          user: plan.user,
          selected_item_ids: selected.items.values.map(&:id)
        )
        selected.items.each_value { |item| selected_counts[item.id] += 1 }
        [ outfit, suggestions ]
      end

      def persist_outfit(plan, date, context, weather, selected)
        outfit = plan.user.outfits.create!(
          prompt: plan.prompt.presence || I18n.t("styling_plans.default_prompt.#{plan.plan_type}"),
          occasion: context["occasion"],
          context: context,
          weather_context: weather,
          name: Stylist::OutfitName.call(items: selected.items, occasion: context["occasion"]),
          recommendation_score: selected.score,
          score_breakdown: selected.score_breakdown,
          explanation: I18n.t("styling_plans.daily_explanation", date: I18n.l(date)),
          status: :recommended,
          recommended_for: plan.user.timezone.present? ? date.in_time_zone(plan.user.timezone).change(hour: 12) : date.to_time.change(hour: 12)
        )
        selected.items.each_with_index do |(role, clothing_item), position|
          outfit.outfit_items.create!(clothing_item: clothing_item, role: role, position: position)
        end
        outfit
      end

      def packing_summary(plan, selected_counts, suggestions)
        item_ids = selected_counts.keys
        items = plan.user.clothing_items.where(id: item_ids).index_by(&:id)
        packed_items = selected_counts.sort_by { |item_id, count| [ -count, item_id ] }.map do |item_id, count|
          item = items.fetch(item_id)
          { "clothing_item_id" => item_id, "name" => item.name, "category" => item.category, "wear_count" => count }
        end

        {
          "strategy" => I18n.t("styling_plans.compact_packing_strategy"),
          "days" => plan.entries.size,
          "unique_item_count" => item_ids.size,
          "items" => packed_items,
          "suggestions" => suggestions.map(&:stringify_keys).uniq { |item| item["key"] }
                                      .sort_by { |item| PRIORITIES.fetch(item["priority"], 3) }.first(3)
        }
      end
    end
  end
end
