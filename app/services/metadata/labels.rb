module Metadata
  class Labels
    CONTEXT_FIELDS = %w[occasion formality activity season usage].freeze

    class << self
      def for(value, scope:)
        return if value.blank?

        I18n.t("api_labels.#{scope}.#{value}", default: value.to_s.humanize)
      end

      def list(values, scope:)
        Array(values).map { |value| self.for(value, scope: scope) }
      end

      def context(value)
        value.to_h.deep_dup.tap do |context|
          CONTEXT_FIELDS.each do |field|
            context["#{field}_label"] = self.for(context[field], scope: field) if context[field].present?
          end

          context["weather"] = weather(context["weather"]) if context["weather"].is_a?(Hash)
        end
      end

      def weather(value)
        value.to_h.deep_dup.tap do |weather|
          weather["condition_label"] = self.for(weather["condition"], scope: :weather_condition) if weather["condition"].present?
        end
      end

      def weather_list(values)
        Array(values).map { |value| weather(value) }
      end

      def fit_preferences(value)
        value.to_h.transform_values { |preference| label_fit_preference(preference) }
      end

      def packing_summary(value)
        value.to_h.deep_dup.tap do |summary|
          summary["items"] = Array(summary["items"]).map { |item| packing_item(item) }
          summary["categories"] = Array(summary["categories"]).map { |category| packing_category(category) }
          summary["suggestions"] = Array(summary["suggestions"]).map { |item| suggestion(item) }
        end
      end

      def suggestion(value)
        value.to_h.deep_dup.tap do |suggestion|
          %w[type priority action role].each do |field|
            next if suggestion[field].blank?

            suggestion["#{field}_label"] = self.for(suggestion[field], scope: "suggestion_#{field}")
          end
          suggestion["suggested_subcategory_labels"] = list(suggestion["suggested_subcategories"], scope: :clothing_subcategory)
        end
      end

      private

      def label_fit_preference(value)
        return value.transform_values { |nested| label_fit_preference(nested) } if value.is_a?(Hash)
        return list(value, scope: :clothing_fit) if value.is_a?(Array)

        self.for(value, scope: :clothing_fit)
      end

      def packing_item(value)
        value.to_h.deep_dup.tap do |item|
          item["category_label"] = self.for(item["category"], scope: :clothing_category)
        end
      end

      def packing_category(value)
        value.to_h.deep_dup.tap do |category|
          category["category_label"] = self.for(category["category"], scope: :clothing_category)
        end
      end
    end
  end
end
