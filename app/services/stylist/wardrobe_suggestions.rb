module Stylist
  class WardrobeSuggestions
    OPTIONAL_ROLES = %w[shoes accessory].freeze

    class << self
      def call(candidates:, context:)
        suggestions = OPTIONAL_ROLES.filter_map do |role|
          suggestion(role) if candidates.fetch(role).empty?
        end
        if outerwear_relevant?(context) && candidates.fetch("outerwear").empty?
          suggestions << suggestion("outerwear")
        end
        suggestions
      end

      private

      def suggestion(role)
        {
          key: "add_#{role}",
          role: role,
          message: I18n.t("stylist.suggestions.add_#{role}")
        }
      end

      def outerwear_relevant?(context)
        context["season"].in?(%w[fall winter]) || context["formality"] == "formal"
      end
    end
  end
end
