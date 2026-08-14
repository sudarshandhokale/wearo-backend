require "yaml"

module AiEvaluations
  class OutfitRecommendationRunner
    DEFAULT_SCENARIO_PATH = Rails.root.join("config/ai_evaluations/outfit_recommendations.yml").freeze
    EVALUATION_ROLLBACK = Class.new(StandardError)
    WEATHER_PROTECTION_TOKENS = %w[
      rain raincoat waterproof water_resistant umbrella trench_coat coat boots
    ].freeze

    class << self
      def call(path: DEFAULT_SCENARIO_PATH)
        scenarios = YAML.safe_load_file(path, permitted_classes: [ Date ], aliases: false)
        Summary.new(results: Array(scenarios).map { |scenario| run_scenario(scenario.deep_stringify_keys) })
      end

      private

      def run_scenario(scenario)
        result = nil
        ActiveRecord::Base.transaction(requires_new: true) do
          user = create_user!(scenario)
          items = create_items!(user, scenario.fetch("wardrobe", []))
          create_wear_history!(user, items)
          recommended = recommend(user, scenario.fetch("context", {}))
          checks = evaluate(recommended, scenario.fetch("expectations", {}))

          result = ScenarioResult.new(
            id: scenario.fetch("id"),
            name: scenario.fetch("name"),
            passed: checks.all?(&:passed),
            checks: checks,
            recommended_outfits: serialize_recommendations(recommended),
            error: nil
          )
          raise EVALUATION_ROLLBACK
        end
      rescue EVALUATION_ROLLBACK
        result
      rescue StandardError => error
        ScenarioResult.new(
          id: scenario["id"],
          name: scenario["name"],
          passed: false,
          checks: [],
          recommended_outfits: [],
          error: "#{error.class.name}: #{error.message}"
        )
      end

      def create_user!(scenario)
        timestamp = Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
        user = User.create!(
          first_name: "AI",
          last_name: "Evaluation",
          email: "ai-eval-#{scenario.fetch("id")}-#{timestamp}@example.com",
          password: SecureRandom.hex(12),
          timezone: "UTC",
          country_code: "US",
          accept_terms: true,
          accept_privacy: true,
          accept_ai_processing: true,
          confirm_adult: true,
          confirmed_at: Time.current
        )
        profile = scenario.fetch("profile", {})
        user.style_profile.update!(
          preferred_styles: Array(profile["preferred_styles"]),
          preferred_colors: Array(profile["preferred_colors"]),
          disliked_colors: Array(profile["disliked_colors"]),
          fit_preferences: profile.fetch("fit_preferences", {}),
          additional_preferences: profile.fetch("additional_preferences", {})
        )
        user
      end

      def create_items!(user, item_attributes)
        item_attributes.each_with_object({}) do |attributes, index|
          item = user.clothing_items.create!(
            wardrobe: user.wardrobe,
            name: attributes.fetch("name"),
            garment_type: attributes["garment_type"] || attributes["subcategory"],
            category: attributes.fetch("category"),
            subcategory: attributes.fetch("subcategory"),
            primary_color: attributes["primary_color"],
            secondary_colors: Array(attributes["secondary_colors"]),
            pattern: attributes["pattern"] || "solid",
            material: attributes["material"],
            fit: attributes["fit"] || "regular",
            season_tags: Array(attributes["season_tags"]),
            occasion_tags: Array(attributes["occasion_tags"]),
            style_tags: Array(attributes["style_tags"]),
            cultural_tags: Array(attributes["cultural_tags"]),
            usage_tags: Array(attributes["usage_tags"]),
            user_usage_tags: attributes["user_usage_tags"],
            formality_score: attributes["formality_score"],
            ai_metadata: attributes.slice("worn_days_ago"),
            status: :ready
          )
          index[item.name] = item
        end
      end

      def create_wear_history!(user, items)
        items.each_value do |item|
          worn_days_ago = item.ai_metadata["worn_days_ago"]
          next if worn_days_ago.blank?

          outfit = user.outfits.create!(
            name: "Evaluation Worn Outfit",
            status: :worn,
            context: {},
            weather_context: {},
            score_breakdown: {}
          )
          outfit.outfit_items.create!(clothing_item: item, role: item.category, position: 0)
          user.wear_histories.create!(outfit: outfit, worn_on: Time.current.to_date - worn_days_ago.to_i.days)
        end
      end

      def recommend(user, context)
        context = context.to_h.stringify_keys
        personalization = Personalization::Snapshot.call(user: user)
        candidates = Stylist::CandidateSelector.call(user: user, context: context)
        combinations = Stylist::CombinationBuilder.call(candidates: candidates, context: context)
        combinations
          .map do |combination|
            Stylist::CompatibilityScorer.call(
              combination: combination,
              context: context,
              style_profile: user.style_profile,
              personalization: personalization
            )
          end
          .sort_by { |combination| -combination.score }
          .first(Stylist::RankRecommendations::RECOMMENDATION_LIMIT)
      end

      def evaluate(recommended, expectations)
        expectations = expectations.to_h.stringify_keys
        [
          min_recommendations_check(recommended, expectations["min_recommendations"]),
          required_categories_check(recommended, expectations["required_categories"]),
          avoid_colors_check(recommended, expectations["avoid_colors"]),
          preferred_usage_check(recommended, expectations["preferred_usage"]),
          weather_protection_check(recommended, expectations["require_weather_protection"]),
          recently_worn_check(recommended, expectations["avoid_recently_worn_days"])
        ].compact
      end

      def min_recommendations_check(recommended, expected_count)
        return if expected_count.blank?

        passed = recommended.length >= expected_count.to_i
        CheckResult.new(
          name: "min_recommendations",
          passed: passed,
          message: passed ? "Generated #{recommended.length} recommendation(s)" : "Expected at least #{expected_count}, got #{recommended.length}",
          details: { expected: expected_count.to_i, actual: recommended.length }
        )
      end

      def required_categories_check(recommended, required_categories)
        required_categories = Array(required_categories)
        return if required_categories.empty?

        missing = required_categories - recommended.first&.items.to_h.values.to_a.map(&:category).to_a
        CheckResult.new(
          name: "required_categories",
          passed: missing.empty?,
          message: missing.empty? ? "Required categories are present" : "Missing categories: #{missing.join(", ")}",
          details: { required: required_categories, missing: missing }
        )
      end

      def avoid_colors_check(recommended, avoid_colors)
        avoid_colors = Array(avoid_colors)
        return if avoid_colors.empty?

        selected_colors = recommended.flat_map { |combination| combination.items.values.filter_map(&:primary_color) }.uniq
        matches = selected_colors & avoid_colors
        CheckResult.new(
          name: "avoid_colors",
          passed: matches.empty?,
          message: matches.empty? ? "Avoided blocked colors" : "Selected blocked colors: #{matches.join(", ")}",
          details: { avoided: avoid_colors, selected: selected_colors }
        )
      end

      def preferred_usage_check(recommended, preferred_usage)
        return if preferred_usage.blank? || recommended.empty?

        mismatches = recommended.first.items.values.reject { |item| item.effective_usage_tags.blank? || item.effective_usage_tags.include?(preferred_usage) }
        CheckResult.new(
          name: "preferred_usage",
          passed: mismatches.empty?,
          message: mismatches.empty? ? "Top recommendation matches usage" : "Usage mismatch: #{mismatches.map(&:name).join(", ")}",
          details: { preferred_usage: preferred_usage, mismatches: mismatches.map(&:name) }
        )
      end

      def weather_protection_check(recommended, required)
        return unless ActiveModel::Type::Boolean.new.cast(required)

        protected = recommended.first&.items.to_h.values.to_a.any? do |item|
          ([ item.category, item.subcategory, item.garment_type ] + item.style_tags).compact.intersect?(WEATHER_PROTECTION_TOKENS)
        end
        CheckResult.new(
          name: "weather_protection",
          passed: protected,
          message: protected ? "Top recommendation includes weather protection" : "Top recommendation lacks weather protection",
          details: { required_tokens: WEATHER_PROTECTION_TOKENS }
        )
      end

      def recently_worn_check(recommended, days)
        return if days.blank? || recommended.empty?

        cutoff = Time.current.to_date - days.to_i.days
        recently_worn = recommended.first.items.values.select do |item|
          item.outfits.joins(:wear_histories).where(wear_histories: { worn_on: cutoff..Time.current.to_date }).exists?
        end
        CheckResult.new(
          name: "avoid_recently_worn",
          passed: recently_worn.empty?,
          message: recently_worn.empty? ? "Top recommendation avoids recently worn items" : "Top recommendation includes recently worn items: #{recently_worn.map(&:name).join(", ")}",
          details: { days: days.to_i, recently_worn: recently_worn.map(&:name) }
        )
      end

      def serialize_recommendations(recommended)
        recommended.map do |combination|
          {
            score: combination.score,
            items: combination.items.transform_values do |item|
              {
                id: item.id,
                name: item.name,
                category: item.category,
                color: item.primary_color,
                usage_tags: item.effective_usage_tags
              }
            end
          }
        end
      end
    end
  end
end
