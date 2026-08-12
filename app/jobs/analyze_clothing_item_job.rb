class AnalyzeClothingItemJob < ApplicationJob
  queue_as :clothing_analysis

  discard_on ActiveJob::DeserializationError

  def perform(clothing_item_id)
    clothing_item = ClothingItem.find(clothing_item_id)
    return if clothing_item.discarded?
    return mark_consent_required(clothing_item) unless clothing_item.user.ai_processing_consented?

    result = ClothingAnalysis::Analyze.call(clothing_item)
    clothing_item.update!(
      result.attributes.merge(
        status: :ready,
        ai_analyzed_at: Time.current,
        ai_metadata: result.metadata
      )
    )
    schedule_image_polish(clothing_item)
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    mark_analysis_failed(clothing_item, error)
  end

  private

  def schedule_image_polish(clothing_item)
    return unless ClothingImage.auto_polish_enabled?
    return if clothing_item.polished_image.attached? &&
              clothing_item.ai_metadata.dig("image_polish", "source_checksum") == clothing_item.image_checksum
    return if polish_in_progress_for_current_source?(clothing_item)

    clothing_item.update_column(
      :ai_metadata,
      clothing_item.ai_metadata.merge(
        "image_polish" => { "status" => "queued", "source_checksum" => clothing_item.image_checksum }
      )
    )
    GenerateClothingItemPolishedImageJob.perform_later(clothing_item.id, clothing_item.image_checksum)
  end

  def polish_in_progress_for_current_source?(clothing_item)
    metadata = clothing_item.ai_metadata.fetch("image_polish", {})
    metadata["status"].in?(%w[queued processing]) && metadata["source_checksum"] == clothing_item.image_checksum
  end

  def mark_analysis_failed(clothing_item, error)
    Rails.logger.error("Clothing analysis failed for item #{clothing_item&.id}: #{error.class}: #{error.message}")
    return if clothing_item.blank? || clothing_item.discarded?

    clothing_item.update_columns(
      status: "analysis_failed",
      ai_analyzed_at: nil,
      ai_metadata: clothing_item.ai_metadata.merge("error" => { "code" => "analysis_failed" }),
      updated_at: Time.current
    )
  end

  def mark_consent_required(clothing_item)
    clothing_item.update_columns(
      status: "analysis_failed",
      ai_analyzed_at: nil,
      ai_metadata: clothing_item.ai_metadata.merge("error" => { "code" => "ai_processing_consent_required" }),
      updated_at: Time.current
    )
  end
end
