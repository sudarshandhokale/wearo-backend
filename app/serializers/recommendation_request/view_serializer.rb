class RecommendationRequest::ViewSerializer < ApplicationSerializer
  attributes :id,
             :prompt,
             :context,
             :wardrobe_suggestions,
             :status,
             :status_label,
             :ranking_source,
             :ranking_source_label,
             :provider,
             :model,
             :ai_usage,
             :failure_code,
             :recommended_for,
             :completed_at,
             :outfits,
             :created_at,
             :updated_at

  labeled_attributes :status, scope: :recommendation_status
  labeled_attributes :ranking_source

  def context
    labeled_context(object.context)
  end

  def wardrobe_suggestions
    object.wardrobe_suggestions.map { |suggestion| Metadata::Labels.suggestion(suggestion) }
  end

  def ai_usage
    {
      input_tokens: object.input_tokens,
      output_tokens: object.output_tokens,
      total_tokens: object.total_tokens,
      attempt_count: object.attempt_count
    }
  end

  def recommended_for
    format_datetime_value(object.recommended_for)
  end

  def completed_at
    format_datetime_value(object.completed_at)
  end

  def outfits
    return unless object.association(:outfits).loaded?

    object.outfits.map { |outfit| Outfit::ViewSerializer.new(outfit).serializable_hash }
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
