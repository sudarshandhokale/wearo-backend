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
             :consents,
             :created_at,
             :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def full_body_image
    return unless object.full_body_image.attached?

    {
      signed_id: object.full_body_image.blob.signed_id,
      url: Rails.application.routes.url_helpers.api_v1_medium_path(object.full_body_image.blob.signed_id)
    }
  end

  def consents
    {
      terms: { accepted_at: format_datetime_value(object.terms_accepted_at), version: object.terms_version },
      privacy: { accepted_at: format_datetime_value(object.privacy_accepted_at), version: object.privacy_version },
      ai_processing: { accepted_at: format_datetime_value(object.ai_processing_consent_at) },
      adult_confirmed_at: format_datetime_value(object.adult_confirmed_at),
      full_body_image: { accepted_at: format_datetime_value(object.full_body_image_consent_at) }
    }
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
