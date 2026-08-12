module ClothingAnalysis
  class Analyze
    class << self
      def call(clothing_item, provider: Providers::Openai.new)
        provider_result = provider.call(image: clothing_item.image, user_id: clothing_item.user_id)
        normalized_result = NormalizeResult.call(provider_result.fetch(:result))
        ResultSchema.validate!(normalized_result)

        AnalysisResult.new(
          attributes: normalized_result.slice(*ResultSchema::PERSISTED_FIELDS),
          metadata: provider_result.fetch(:metadata, {}).merge("confidence" => normalized_result["confidence"]).compact
        )
      rescue KeyError
        raise InvalidResultError, "Analysis provider returned an invalid response"
      end
    end
  end
end
