class Outfit::ViewSerializer < ApplicationSerializer
  attributes :id,
             :recommendation_request_id,
             :name,
             :prompt,
             :occasion,
             :occasion_label,
             :context,
             :weather_context,
             :recommendation_score,
             :score_breakdown,
             :explanation,
             :status,
             :status_label,
             :rating,
             :feedback_note,
             :status_updated_at,
             :recommended_for,
             :cover_images,
             :items,
             :created_at,
             :updated_at

  labeled_attributes :occasion
  labeled_attributes :status, scope: :outfit_status

  def context
    labeled_context(object.context)
  end

  def weather_context
    Metadata::Labels.weather(object.weather_context)
  end

  def recommendation_score
    object.recommendation_score&.to_f
  end

  def name
    object.name.presence || Stylist::OutfitName.call(
      items: object.outfit_items.map { |outfit_item| [ outfit_item.role, outfit_item.clothing_item ] },
      occasion: object.occasion
    )
  end

  def recommended_for
    format_datetime_value(object.recommended_for)
  end

  def status_updated_at
    format_datetime_value(object.status_updated_at)
  end

  def items
    object.outfit_items.map do |outfit_item|
      OutfitItem::ViewSerializer.new(outfit_item).serializable_hash
    end
  end

  def cover_images
    visualization = preferred_visualization
    return [ visualization_cover(visualization) ] if visualization

    item_covers
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end

  private

  def preferred_visualization
    object.outfit_visualizations
          .select { |visualization| visualization.ready? && visualization.image.attached? }
          .max_by { |visualization| [ visualization.try_on? ? 1 : 0, visualization.created_at ] }
  end

  def visualization_cover(visualization)
    attachment_payload(visualization.image).merge(
      kind: visualization.try_on? ? "outfit_try_on" : "outfit_flat_lay",
      kind_label: Metadata::Labels.for(visualization.try_on? ? "outfit_try_on" : "outfit_flat_lay", scope: :cover_image_kind),
      generated: true,
      personalized: visualization.try_on?,
      visualization_id: visualization.id
    )
  end

  def item_covers
    object.outfit_items.filter_map do |outfit_item|
      clothing_item = outfit_item.clothing_item
      attachment = clothing_item.polished_image.attached? ? clothing_item.polished_image : clothing_item.image
      next unless attachment.attached?

      attachment_payload(attachment).merge(
        kind: clothing_item.polished_image.attached? ? "polished_item" : "original_item",
        kind_label: Metadata::Labels.for(clothing_item.polished_image.attached? ? "polished_item" : "original_item", scope: :cover_image_kind),
        generated: clothing_item.polished_image.attached?,
        personalized: false,
        clothing_item_id: clothing_item.id
      )
    end
  end

  def attachment_payload(attachment)
    {
      signed_id: attachment.blob.signed_id,
      url: Rails.application.routes.url_helpers.api_v1_medium_path(attachment.blob.signed_id)
    }
  end
end
