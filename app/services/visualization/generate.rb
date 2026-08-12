module Visualization
  class Generate
    RESERVED_TOKENS = 15_000

    class << self
      def call(visualization, provider: Providers::Openai.new)
        visualization.update!(status: :processing)
        ai_request = Ai::UsageTracker.start!(
          user: visualization.user,
          operation: "outfit_visualization",
          trackable: visualization,
          reserved_tokens: RESERVED_TOKENS
        )
        result = provider.call(visualization: visualization)
        metadata = result.fetch(:metadata).stringify_keys

        visualization.image.attach(
          io: StringIO.new(result.fetch(:image)),
          filename: "outfit-visualization-#{visualization.id}.png",
          content_type: "image/png"
        )
        visualization.update!(
          status: :ready,
          provider: metadata["provider"],
          model: metadata["model"],
          response_id: metadata["response_id"],
          metadata: visualization.metadata.merge(metadata.except("usage")),
          completed_at: Time.current
        )
        Ai::UsageTracker.succeed!(ai_request, metadata)
        visualization
      rescue StandardError => error
        Ai::UsageTracker.fail!(ai_request, error)
        visualization.update_columns(
          status: "failed",
          failure_code: error.class.name.demodulize.underscore,
          completed_at: Time.current,
          updated_at: Time.current
        ) if visualization.persisted?
        raise
      ensure
        visualization.reference_image.purge_later if visualization.persisted? && visualization.reference_image.attached?
      end
    end
  end
end
