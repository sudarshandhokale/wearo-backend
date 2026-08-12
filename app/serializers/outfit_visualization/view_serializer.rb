class OutfitVisualization::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :mode, :status, :provider, :model, :metadata, :failure_code,
             :image, :completed_at, :created_at, :updated_at

  def image
    return unless object.image.attached?

    {
      signed_id: object.image.blob.signed_id,
      url: Rails.application.routes.url_helpers.rails_storage_proxy_path(object.image, only_path: true)
    }
  end

  def completed_at
    format_datetime_value(object.completed_at)
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
