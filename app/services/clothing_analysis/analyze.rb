module ClothingAnalysis
  class Analyze
    class << self
      def call(clothing_item, provider: Providers::Openai.new)
        ai_request = Ai::UsageTracker.start!(
          user: clothing_item.user,
          operation: "clothing_analysis",
          trackable: clothing_item,
          reserved_tokens: 5_000
        )
        provider_result = provider.call(image: clothing_item.image, user_id: clothing_item.user_id)
        normalized_result = NormalizeResult.call(provider_result.fetch(:result))
        ResultSchema.validate!(normalized_result)
        metadata = provider_result.fetch(:metadata, {})
        Ai::UsageTracker.succeed!(ai_request, metadata)

        AnalysisResult.new(
          attributes: normalized_result.slice(*ResultSchema::PERSISTED_FIELDS),
          metadata: metadata.merge("confidence" => normalized_result["confidence"]).compact
        )
      rescue KeyError
        error = InvalidResultError.new("Analysis provider returned an invalid response")
        Ai::UsageTracker.fail!(ai_request, error)
        raise error
      rescue StandardError => error
        Ai::UsageTracker.fail!(ai_request, error)
        raise
      end
    end
  end
end
