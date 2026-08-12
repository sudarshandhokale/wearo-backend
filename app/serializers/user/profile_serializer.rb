class User::ProfileSerializer < ApplicationSerializer
  attributes :id,
             :first_name,
             :last_name,
             :full_name,
             :email,
             :timezone,
             :country_code,
             :preferred_city,
             :full_body_image,
             :created_at,
             :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def full_body_image
    return unless object.full_body_image.attached?

    {
      signed_id: object.full_body_image.blob.signed_id,
      url: Rails.application.routes.url_helpers.rails_storage_proxy_path(object.full_body_image, only_path: true)
    }
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
