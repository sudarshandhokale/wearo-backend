class ClothingItem::ViewSerializer < ApplicationSerializer
  attributes :id,
             :wardrobe_id,
             :name,
             :garment_type,
             :category,
             :category_label,
             :subcategory,
             :subcategory_label,
             :primary_color,
             :secondary_colors,
             :pattern,
             :material,
             :fit,
             :fit_label,
             :season_tags,
             :season_tag_labels,
             :occasion_tags,
             :occasion_tag_labels,
             :style_tags,
             :style_tag_labels,
             :cultural_tags,
             :cultural_tag_labels,
             :usage_tags,
             :usage_tag_labels,
             :user_usage_tags,
             :user_usage_tag_labels,
             :effective_usage_tags,
             :effective_usage_tag_labels,
             :usage_source,
             :usage_source_label,
             :formality_score,
             :status,
             :status_label,
             :ai_metadata,
             :ai_analyzed_at,
             :image,
             :polished_image,
             :display_image,
             :cover_image,
             :image_polish,
             :created_at,
             :updated_at

  labeled_attributes :category, scope: :clothing_category
  labeled_attributes :subcategory, scope: :clothing_subcategory
  labeled_attributes :fit, scope: :clothing_fit
  labeled_attributes :status, scope: :clothing_status

  def season_tag_labels
    Metadata::Labels.list(object.season_tags, scope: :season)
  end

  def occasion_tag_labels
    Metadata::Labels.list(object.occasion_tags, scope: :occasion)
  end

  def style_tag_labels
    Metadata::Labels.list(object.style_tags, scope: :style)
  end

  def cultural_tag_labels
    Metadata::Labels.list(object.cultural_tags, scope: :cultural_tag)
  end

  def usage_tag_labels
    Metadata::Labels.list(object.usage_tags, scope: :clothing_usage)
  end

  def user_usage_tag_labels
    return if object.user_usage_tags.nil?

    Metadata::Labels.list(object.user_usage_tags, scope: :clothing_usage)
  end

  def effective_usage_tag_labels
    Metadata::Labels.list(object.effective_usage_tags, scope: :clothing_usage)
  end

  def usage_source_label
    Metadata::Labels.for(object.usage_source, scope: :usage_source)
  end

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
      kind_label: Metadata::Labels.for(object.polished_image.attached? ? "polished_item" : "original_item", scope: :cover_image_kind),
      generated: object.polished_image.attached?,
      clothing_item_id: object.id
    )
  end

  def image_polish
    object.ai_metadata.fetch("image_polish", { "status" => "not_requested" }).deep_dup.tap do |image_polish|
      image_polish["status_label"] = Metadata::Labels.for(image_polish["status"], scope: :image_polish_status)
    end
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
