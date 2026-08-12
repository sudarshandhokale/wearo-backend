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
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    mark_analysis_failed(clothing_item, error)
  end

  private

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
