module Stylist
  class CandidateSelector
    REQUIRED_COMBINATIONS = OutfitTaxonomy.base_combinations.freeze
    BASE_ROLES = REQUIRED_COMBINATIONS.flatten.uniq.freeze
    OPTIONAL_ROLES = OutfitTaxonomy.optional_role_keys.freeze
    ITEMS_PER_ROLE = 10
    FORMALITY_TARGETS = {
      "casual" => 3,
      "smart_casual" => 5,
      "formal" => 8
    }.freeze

    class << self
      def call(user:, context:)
        grouped_items = user.clothing_items.active.ready.recent_first.group_by(&:category)
        candidates = (BASE_ROLES + OPTIONAL_ROLES).to_h do |role|
          items = Array(grouped_items[role]).select { |item| suitable?(item, context) }.first(ITEMS_PER_ROLE)
          [ role, items ]
        end

        unless valid_base_available?(candidates)
          missing_roles = BASE_ROLES.select { |role| candidates[role].empty? }
          raise InsufficientWardrobeError.new(missing_roles, required_combinations: REQUIRED_COMBINATIONS)
        end

        candidates
      end

      private

      def valid_base_available?(candidates)
        REQUIRED_COMBINATIONS.any? do |roles|
          roles.all? { |role| candidates.fetch(role).any? }
        end
      end

      def suitable?(item, context)
        suitable_formality?(item, context["formality"]) &&
          suitable_season?(item, context["season"]) &&
          suitable_user_usage?(item, context)
      end

      def suitable_formality?(item, formality)
        target = FORMALITY_TARGETS[formality]
        item.formality_score.blank? || target.blank? || (item.formality_score - target).abs <= 5
      end

      def suitable_season?(item, season)
        return true if season.blank? || item.season_tags.empty?

        item.season_tags.intersect?([ season, "all_season" ])
      end

      def suitable_user_usage?(item, context)
        item.user_usage_tags.nil? || ClothingUsageTaxonomy.suitable?(item.user_usage_tags, context)
      end
    end
  end
end
