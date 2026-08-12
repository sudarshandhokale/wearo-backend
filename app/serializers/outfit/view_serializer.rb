class Outfit::ViewSerializer < ApplicationSerializer
  attributes :id,
             :prompt,
             :occasion,
             :context,
             :weather_context,
             :recommendation_score,
             :explanation,
             :status,
             :recommended_for,
             :items,
             :created_at,
             :updated_at

  def recommendation_score
    object.recommendation_score&.to_f
  end

  def recommended_for
    format_datetime_value(object.recommended_for)
  end

  def items
    object.outfit_items.map do |outfit_item|
      OutfitItem::ViewSerializer.new(outfit_item).serializable_hash
    end
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
