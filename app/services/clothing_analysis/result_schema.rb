module ClothingAnalysis
  class ResultSchema
    PERSISTED_FIELDS = %w[
      name
      garment_type
      category
      subcategory
      primary_color
      secondary_colors
      pattern
      material
      season_tags
      occasion_tags
      style_tags
      cultural_tags
      formality_score
    ].freeze
    FIELDS = (PERSISTED_FIELDS + [ "confidence" ]).freeze

    SCHEMA = {
      type: "object",
      additionalProperties: false,
      required: FIELDS,
      properties: {
        name: { type: [ "string", "null" ] },
        garment_type: { type: [ "string", "null" ] },
        category: { type: [ "string", "null" ] },
        subcategory: { type: [ "string", "null" ] },
        primary_color: { type: [ "string", "null" ] },
        secondary_colors: { type: "array", items: { type: "string" } },
        pattern: { type: [ "string", "null" ] },
        material: { type: [ "string", "null" ] },
        season_tags: { type: "array", items: { type: "string" } },
        occasion_tags: { type: "array", items: { type: "string" } },
        style_tags: { type: "array", items: { type: "string" } },
        cultural_tags: { type: "array", items: { type: "string" } },
        formality_score: { type: [ "integer", "null" ], minimum: 1, maximum: 10 },
        confidence: { type: [ "number", "null" ], minimum: 0, maximum: 1 }
      }
    }.freeze

    class << self
      def validate!(result)
        raise InvalidResultError, "Analysis result must be an object" unless result.is_a?(Hash)

        missing_fields = FIELDS - result.keys
        raise InvalidResultError, "Analysis result is missing required fields" if missing_fields.any?

        validate_arrays!(result)
        validate_taxonomy!(result)
        validate_formality!(result["formality_score"])
        validate_confidence!(result["confidence"])

        result
      end

      private

      def validate_arrays!(result)
        %w[secondary_colors season_tags occasion_tags style_tags cultural_tags].each do |field|
          value = result[field]
          raise InvalidResultError, "Analysis result contains an invalid array" unless value.is_a?(Array) && value.all? { |item| item.is_a?(String) }
        end
      end

      def validate_taxonomy!(result)
        category = result["category"]
        subcategory = result["subcategory"]

        raise InvalidResultError, "Analysis result contains an invalid category" if category.present? && ClothingTaxonomy.category_keys.exclude?(category)
        return if subcategory.blank?

        valid_subcategories = ClothingTaxonomy.subcategory_keys(category)
        raise InvalidResultError, "Analysis result contains an invalid subcategory" if category.blank? || valid_subcategories.exclude?(subcategory)
      end

      def validate_formality!(value)
        return if value.nil? || (value.is_a?(Integer) && value.between?(1, 10))

        raise InvalidResultError, "Analysis result contains an invalid formality score"
      end

      def validate_confidence!(value)
        return if value.nil? || (value.is_a?(Numeric) && value.between?(0, 1))

        raise InvalidResultError, "Analysis result contains an invalid confidence"
      end
    end
  end
end
