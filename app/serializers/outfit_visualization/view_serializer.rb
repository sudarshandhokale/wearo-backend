class OutfitVisualization::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :mode, :status, :provider, :model, :metadata, :failure_code,
             :image, :guidance, :completed_at, :created_at, :updated_at

  def image
    return unless object.image.attached?

    {
      signed_id: object.image.blob.signed_id,
      url: Rails.application.routes.url_helpers.api_v1_medium_path(object.image.blob.signed_id)
    }
  end

  def completed_at
    format_datetime_value(object.completed_at)
  end

  def guidance
    fallback = object.metadata["fallback_reason"] == "person_reference_missing"
    profile_photo_available = object.user.full_body_image.attached?

    {
      personalized: object.try_on?,
      profile_photo_available: profile_photo_available,
      fallback_from_try_on: fallback,
      action: profile_photo_available || object.try_on? ? nil : "upload_full_body_photo",
      message: guidance_message(fallback, profile_photo_available)
    }
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end

  private

  def guidance_message(fallback, profile_photo_available)
    return I18n.t("visualizations.guidance.fallback_to_flat_lay") if fallback
    return I18n.t("visualizations.guidance.personalized") if object.try_on?
    return I18n.t("visualizations.guidance.try_on_available") if profile_photo_available

    I18n.t("visualizations.guidance.upload_for_try_on")
  end
end
