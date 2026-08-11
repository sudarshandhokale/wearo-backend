class StyleProfile::ViewSerializer < ApplicationSerializer
  attributes :id,
             :preferred_styles,
             :preferred_colors,
             :disliked_colors,
             :fit_preferences,
             :additional_preferences,
             :onboarding_completed,
             :created_at,
             :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
