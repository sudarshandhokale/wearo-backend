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
             :polished_image,
             :display_image,
             :cover_image,
             :image_polish,
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
    attachment_payload(object.image)
  end

  def polished_image
    attachment_payload(object.polished_image)
  end

  def display_image
    polished_image || image
  end

  def cover_image
    return unless (attachment = object.polished_image.attached? ? object.polished_image : object.image).attached?

    attachment_payload(attachment).merge(
      kind: object.polished_image.attached? ? "polished_item" : "original_item",
      generated: object.polished_image.attached?,
      clothing_item_id: object.id
    )
  end

  def image_polish
    object.ai_metadata.fetch("image_polish", { "status" => "not_requested" })
  end

  private

  def attachment_payload(attachment)
    return unless attachment.attached?

    {
      signed_id: attachment.blob.signed_id,
      url: Rails.application.routes.url_helpers.api_v1_medium_path(attachment.blob.signed_id)
    }
  end
end
