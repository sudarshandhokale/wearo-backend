class StyleProfile::ViewSerializer < ApplicationSerializer
  attributes :id,
             :preferred_styles,
             :preferred_style_labels,
             :preferred_colors,
             :preferred_color_labels,
             :disliked_colors,
             :disliked_color_labels,
             :fit_preferences,
             :fit_preference_labels,
             :additional_preferences,
             :onboarding_completed,
             :created_at,
             :updated_at

  def preferred_style_labels
    Metadata::Labels.list(object.preferred_styles, scope: :style)
  end

  def preferred_color_labels
    Metadata::Labels.list(object.preferred_colors, scope: :color)
  end

  def disliked_color_labels
    Metadata::Labels.list(object.disliked_colors, scope: :color)
  end

  def fit_preference_labels
    Metadata::Labels.fit_preferences(object.fit_preferences)
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
