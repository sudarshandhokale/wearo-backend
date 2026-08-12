class ClothingItem::ViewSerializer < ApplicationSerializer
  attributes :id,
             :wardrobe_id,
             :name,
             :garment_type,
             :category,
             :subcategory,
             :primary_color,
             :secondary_colors,
             :pattern,
             :material,
             :fit,
             :season_tags,
             :occasion_tags,
             :style_tags,
             :cultural_tags,
             :formality_score,
             :status,
             :ai_metadata,
             :ai_analyzed_at,
             :image,
             :created_at,
             :updated_at

  def ai_analyzed_at
    format_datetime_value(object.ai_analyzed_at)
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end

  def image
    return unless object.image.attached?

    {
      signed_id: object.image.blob.signed_id,
      url: Rails.application.routes.url_helpers.api_v1_medium_path(object.image.blob.signed_id)
    }
  end
end
