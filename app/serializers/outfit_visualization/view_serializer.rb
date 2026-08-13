class OutfitVisualization::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :mode, :mode_label, :status, :status_label, :provider, :model, :metadata, :failure_code,
             :failure_message, :retry_after, :image, :guidance, :completed_at, :created_at, :updated_at

  labeled_attributes :mode, scope: :visualization_mode
  labeled_attributes :status, scope: :visualization_status

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

  def failure_code
    return unless object.failed?

    object.failure_code == "usage_limit_exceeded_error" ? "ai_usage_limit_reached" : object.failure_code
  end

  def failure_message
    return unless object.failed?

    I18n.t("visualizations.failures.#{failure_code}", default: I18n.t("visualizations.failures.generation_failed"))
  end

  def retry_after
    return unless failure_code == "ai_usage_limit_reached"

    format_datetime_value(Time.current.in_time_zone(object.user.timezone).tomorrow.beginning_of_day)
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
