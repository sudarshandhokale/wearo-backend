class GenerateClothingItemPolishedImageJob < ApplicationJob
  queue_as :visualizations

  discard_on ActiveJob::DeserializationError

  def perform(clothing_item_id, source_checksum)
    clothing_item = ClothingItem.find(clothing_item_id)
    return if clothing_item.discarded? || clothing_item.image_checksum != source_checksum
    return mark_consent_required(clothing_item) unless clothing_item.user.ai_processing_consented?

    update_status(clothing_item, "processing")
    ClothingImage::Polish.call(clothing_item)
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    mark_failed(clothing_item, error)
  end

  private

  def update_status(clothing_item, status, extra = {})
    current = clothing_item.ai_metadata.fetch("image_polish", {})
    clothing_item.update_column(
      :ai_metadata,
      clothing_item.ai_metadata.merge("image_polish" => current.merge("status" => status).merge(extra))
    )
  end

  def mark_failed(clothing_item, error)
    Rails.logger.error("Clothing image polish failed for item #{clothing_item&.id}: #{error.class}: #{error.message}")
    return if clothing_item.blank? || clothing_item.discarded?

    update_status(clothing_item, "failed", "error" => { "code" => "image_polish_failed" })
  end

  def mark_consent_required(clothing_item)
    update_status(clothing_item, "failed", "error" => { "code" => "ai_processing_consent_required" })
  end
end
