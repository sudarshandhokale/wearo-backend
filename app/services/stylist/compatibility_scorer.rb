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
      def call(combination:, context:, style_profile:)
        items = combination.items.values
        breakdown = {
          "color" => color_score(items),
          "occasion" => occasion_score(items, context),
          "weather" => weather_score(items, context),
          "preference" => preference_score(items, style_profile),
          "style" => style_score(items, style_profile),
          "repeat" => 100.0
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
        return 80.0 if season.blank?

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

      def preference_score(items, style_profile)
        return 75.0 if style_profile.blank?

        colors = items.filter_map(&:primary_color)
        return 20.0 if colors.intersect?(style_profile.disliked_colors)
        return 75.0 if style_profile.preferred_colors.empty?

        matches = colors.count { |color| style_profile.preferred_colors.include?(color) }
        70.0 + (30.0 * matches / [ colors.length, 1 ].max)
      end

      def style_score(items, style_profile)
        return 75.0 if style_profile.blank? || style_profile.preferred_styles.empty?

        average(items.map do |item|
          item.style_tags.intersect?(style_profile.preferred_styles) ? 100.0 : 55.0
        end)
      end

      def average(values)
        values.sum.to_f / values.length
      end
    end
  end
end
