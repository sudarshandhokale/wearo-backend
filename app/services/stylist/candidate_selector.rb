module Stylist
  class CandidateSelector
    REQUIRED_ROLES = %w[top bottom shoes].freeze
    OPTIONAL_ROLES = %w[outerwear accessory].freeze
    ITEMS_PER_ROLE = 10
    FORMALITY_TARGETS = {
      "casual" => 3,
      "smart_casual" => 5,
      "formal" => 8
    }.freeze

    class << self
      def call(user:, context:)
        grouped_items = user.clothing_items.active.ready.recent_first.group_by(&:category)
        candidates = (REQUIRED_ROLES + OPTIONAL_ROLES).to_h do |role|
          items = Array(grouped_items[role]).select { |item| suitable?(item, context) }.first(ITEMS_PER_ROLE)
          [ role, items ]
        end

        missing_roles = REQUIRED_ROLES.select { |role| candidates[role].empty? }
        raise InsufficientWardrobeError, missing_roles if missing_roles.any?

        candidates
      end

      private

      def suitable?(item, context)
        suitable_formality?(item, context["formality"]) && suitable_season?(item, context["season"])
      end

      def suitable_formality?(item, formality)
        target = FORMALITY_TARGETS[formality]
        item.formality_score.blank? || target.blank? || (item.formality_score - target).abs <= 5
      end

      def suitable_season?(item, season)
        return true if season.blank? || item.season_tags.empty?

        item.season_tags.intersect?([ season, "all_season" ])
      end
    end
  end
end
