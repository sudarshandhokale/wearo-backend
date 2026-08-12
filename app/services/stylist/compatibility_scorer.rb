module Stylist
  class CompatibilityScorer
    WEIGHTS = {
      "color" => 0.25,
      "occasion" => 0.25,
      "weather" => 0.15,
      "preference" => 0.15,
      "style" => 0.10,
      "repeat" => 0.10
    }.freeze
    NEUTRAL_COLORS = %w[black white gray navy beige brown].freeze
    COLOR_COMPATIBILITY = {
      "blue" => %w[white gray beige brown navy],
      "navy" => %w[white gray beige brown blue],
      "green" => %w[white beige brown navy],
      "red" => %w[black white gray navy],
      "pink" => %w[white gray navy beige],
      "purple" => %w[black white gray beige],
      "orange" => %w[white beige brown navy],
      "yellow" => %w[white gray navy brown]
    }.freeze
    FORMALITY_TARGETS = CandidateSelector::FORMALITY_TARGETS

    class << self
      def call(combination:, context:, style_profile:, personalization: {})
        items = combination.items.values
        breakdown = {
          "color" => color_score(items),
          "occasion" => occasion_score(items, context),
          "weather" => weather_score(items, context),
          "preference" => preference_score(items, style_profile, personalization),
          "style" => style_score(items, style_profile, personalization),
          "repeat" => repeat_score(items, personalization)
        }
        score = breakdown.sum { |key, value| value * WEIGHTS.fetch(key) }.round(2)

        ScoredCombination.new(items: combination.items, score: score, score_breakdown: breakdown.transform_values { |value| value.round(2) })
      end

      private

      def color_score(items)
        colors = items.filter_map(&:primary_color)
        pairs = colors.combination(2).to_a
        return 75.0 if pairs.empty?

        average(pairs.map { |first, second| color_pair_score(first, second) })
      end

      def color_pair_score(first, second)
        return 85.0 if first == second
        return 95.0 if first.in?(NEUTRAL_COLORS) || second.in?(NEUTRAL_COLORS)
        return 90.0 if COLOR_COMPATIBILITY.fetch(first, []).include?(second) || COLOR_COMPATIBILITY.fetch(second, []).include?(first)

        60.0
      end

      def occasion_score(items, context)
        occasion = context["occasion"]
        tag_score = average(items.map do |item|
          if item.occasion_tags.include?(occasion)
            100.0
          elsif item.occasion_tags.empty?
            70.0
          else
            45.0
          end
        end)

        target = FORMALITY_TARGETS[context["formality"]]
        formality_values = items.filter_map(&:formality_score)
        return tag_score if target.blank? || formality_values.empty?

        formality_score = [ 100.0 - ((average(formality_values) - target).abs * 15), 0.0 ].max
        average([ tag_score, formality_score ])
      end

      def weather_score(items, context)
        season = context["season"]
        weather = context["weather"].to_h
        season_score = if season.blank?
          80.0
        else
          average(items.map do |item|
            if item.season_tags.intersect?([ season, "all_season" ])
              100.0
            elsif item.season_tags.empty?
              75.0
            else
              40.0
            end
          end)
        end

        signals = [ season_score ]
        minimum_temperature = weather["apparent_temperature_min_c"]
        precipitation = weather["precipitation_probability"]
        signals << cold_weather_score(items) if minimum_temperature.present? && minimum_temperature.to_f < 10
        signals << wet_weather_score(items) if precipitation.present? && precipitation.to_i >= 50
        average(signals)
      end

      def cold_weather_score(items)
        items.any? { |item| item.category == "outerwear" || item.season_tags.intersect?(%w[fall winter]) } ? 100.0 : 45.0
      end

      def wet_weather_score(items)
        weather_tokens = %w[rain raincoat waterproof water_resistant]
        items.any? { |item| ([ item.garment_type, item.subcategory ] + item.style_tags).compact.intersect?(weather_tokens) } ? 100.0 : 55.0
      end

      def preference_score(items, style_profile, personalization)
        return 75.0 if style_profile.blank?

        colors = items.filter_map(&:primary_color)
        learned = personalization.fetch("learned", {})
        disliked = (style_profile.disliked_colors + Array(learned["disliked_colors"])).uniq
        preferred = (style_profile.preferred_colors + Array(learned["preferred_colors"])).uniq
        color_result = if colors.intersect?(disliked)
          20.0
        elsif preferred.empty?
          75.0
        else
          matches = colors.count { |color| preferred.include?(color) }
          70.0 + (30.0 * matches / [ colors.length, 1 ].max)
        end

        fit_results = items.filter_map { |item| fit_preference_score(item, style_profile.fit_preferences) }
        fit_results.empty? ? color_result : average([ color_result, average(fit_results) ])
      end

      def fit_preference_score(item, preferences)
        return if item.fit.blank?

        preferred_fit = preferences[item.category] || preferences[plural_preference_key(item.category)]
        return if preferred_fit.blank?

        item.fit == preferred_fit ? 100.0 : 55.0
      end

      def plural_preference_key(category)
        { "top" => "tops", "bottom" => "bottoms", "shoe" => "shoes" }.fetch(category, category)
      end

      def style_score(items, style_profile, personalization)
        return 75.0 if style_profile.blank?

        learned = personalization.fetch("learned", {})
        preferred = (style_profile.preferred_styles + Array(learned["preferred_styles"])).uniq
        disliked = Array(learned["disliked_styles"])
        return 75.0 if preferred.empty? && disliked.empty?

        average(items.map do |item|
          if item.style_tags.intersect?(disliked)
            25.0
          elsif item.style_tags.intersect?(preferred)
            100.0
          else
            55.0
          end
        end)
      end

      def repeat_score(items, personalization)
        worn_dates = personalization.fetch("last_worn_by_item_id", {})
        days = items.filter_map do |item|
          date = Date.iso8601(worn_dates[item.id.to_s]) if worn_dates[item.id.to_s].present?
          (Time.current.to_date - date).to_i if date
        rescue Date::Error
          nil
        end
        return 100.0 if days.empty?

        most_recent = days.min
        return 20.0 if most_recent <= 2
        return 45.0 if most_recent <= 7
        return 70.0 if most_recent <= 14

        100.0
      end

      def average(values)
        values.sum.to_f / values.length
      end
    end
  end
end
