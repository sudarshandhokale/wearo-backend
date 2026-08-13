module ClothingImage
  class Polish
    RESERVED_TOKENS = 8_000

    class << self
      def call(clothing_item, provider: Providers::Openai.new)
        ai_request = Ai::UsageTracker.start!(
          user: clothing_item.user,
          operation: "clothing_image_polish",
          trackable: clothing_item,
          reserved_tokens: RESERVED_TOKENS
        )
        result = provider.call(
          image: clothing_item.image,
          category: clothing_item.category,
          subcategory: clothing_item.subcategory
        )
        metadata = result.fetch(:metadata).stringify_keys

        clothing_item.polished_image.attach(
          io: StringIO.new(result.fetch(:image)),
          filename: "clothing-item-#{clothing_item.id}-polished.png",
          content_type: "image/png"
        )
        clothing_item.update!(
          ai_metadata: clothing_item.ai_metadata.merge(
            "image_polish" => metadata.except("usage").merge(
              "status" => "ready",
              "source_checksum" => clothing_item.image_checksum,
              "completed_at" => Time.current.iso8601
            )
          )
        )
        Ai::UsageTracker.succeed!(ai_request, metadata)
        clothing_item
      rescue StandardError => error
        Ai::UsageTracker.fail!(ai_request, error)
        raise
      end
    end
  end
end
