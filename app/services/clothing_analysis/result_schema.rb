module ClothingAnalysis
  class ResultSchema
    TOKEN_PATTERN = "^[a-z0-9]+(?:_[a-z0-9]+)*$".freeze
    PERSISTED_FIELDS = %w[
      name
      garment_type
      category
      subcategory
      primary_color
      secondary_colors
      pattern
      material
      fit
      season_tags
      occasion_tags
      style_tags
      cultural_tags
      usage_tags
      formality_score
    ].freeze
    FIELDS = (PERSISTED_FIELDS + [ "confidence" ]).freeze

    SCHEMA = {
      type: "object",
      additionalProperties: false,
      required: FIELDS,
      properties: {
        name: { type: [ "string", "null" ], maxLength: 120 },
        garment_type: { type: [ "string", "null" ], maxLength: 80 },
        category: { type: [ "string", "null" ], maxLength: 50, pattern: TOKEN_PATTERN },
        subcategory: { type: [ "string", "null" ], maxLength: 50, pattern: TOKEN_PATTERN },
        primary_color: { type: [ "string", "null" ], maxLength: 50, pattern: TOKEN_PATTERN },
        secondary_colors: { type: "array", maxItems: 8, items: { type: "string", maxLength: 50, pattern: TOKEN_PATTERN } },
        pattern: { type: [ "string", "null" ], maxLength: 50, pattern: TOKEN_PATTERN },
        material: { type: [ "string", "null" ], maxLength: 50, pattern: TOKEN_PATTERN },
        fit: { type: [ "string", "null" ], enum: ClothingTaxonomy.fit_keys + [ nil ] },
        season_tags: { type: "array", maxItems: 8, items: { type: "string", maxLength: 50, pattern: TOKEN_PATTERN } },
        occasion_tags: { type: "array", maxItems: 12, items: { type: "string", maxLength: 50, pattern: TOKEN_PATTERN } },
        style_tags: { type: "array", maxItems: 12, items: { type: "string", maxLength: 50, pattern: TOKEN_PATTERN } },
        cultural_tags: { type: "array", maxItems: 12, items: { type: "string", maxLength: 50, pattern: TOKEN_PATTERN } },
        usage_tags: { type: "array", maxItems: 8, items: { type: "string", enum: ClothingUsageTaxonomy.keys } },
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
        validate_guardrails!(result)
        validate_taxonomy!(result)
        validate_usage_tags!(result["usage_tags"])
        validate_formality!(result["formality_score"])
        validate_confidence!(result["confidence"])

        result
      end

      private

      def validate_arrays!(result)
        %w[secondary_colors season_tags occasion_tags style_tags cultural_tags usage_tags].each do |field|
          value = result[field]
          raise InvalidResultError, "Analysis result contains an invalid array" unless value.is_a?(Array) && value.all? { |item| item.is_a?(String) }
        end
      end

      def validate_guardrails!(result)
        Ai::Guardrails.model_text!(result["name"], max_length: 120, allow_nil: true)
        Ai::Guardrails.model_text!(result["garment_type"], max_length: 80, allow_nil: true)
        %w[category subcategory primary_color pattern material fit].each do |field|
          Ai::Guardrails.token!(result[field], allow_nil: true)
        end
        Ai::Guardrails.token_list!(result["secondary_colors"], max_items: 8)
        Ai::Guardrails.token_list!(result["season_tags"], max_items: 8)
        %w[occasion_tags style_tags cultural_tags usage_tags].each do |field|
          Ai::Guardrails.token_list!(result[field])
        end
      rescue Ai::GuardrailViolationError
        raise InvalidResultError, "Analysis result failed guardrail validation"
      end

      def validate_taxonomy!(result)
        category = result["category"]
        subcategory = result["subcategory"]
        fit = result["fit"]

        raise InvalidResultError, "Analysis result contains an invalid category" if category.present? && ClothingTaxonomy.category_keys.exclude?(category)
        raise InvalidResultError, "Analysis result contains an invalid fit" if fit.present? && ClothingTaxonomy.fit_keys.exclude?(fit)
        return if subcategory.blank?

        valid_subcategories = ClothingTaxonomy.subcategory_keys(category)
        raise InvalidResultError, "Analysis result contains an invalid subcategory" if category.blank? || valid_subcategories.exclude?(subcategory)
      end

      def validate_formality!(value)
        return if value.nil? || (value.is_a?(Integer) && value.between?(1, 10))

        raise InvalidResultError, "Analysis result contains an invalid formality score"
      end

      def validate_usage_tags!(value)
        return if value.difference(ClothingUsageTaxonomy.keys).empty?

        raise InvalidResultError, "Analysis result contains an invalid usage context"
      end

      def validate_confidence!(value)
        return if value.nil? || (value.is_a?(Numeric) && value.between?(0, 1))

        raise InvalidResultError, "Analysis result contains an invalid confidence"
      end
    end
  end
end
