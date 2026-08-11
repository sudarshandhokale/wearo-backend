class StyleProfile < ApplicationRecord
  belongs_to :user

  validate :array_preferences
  validate :object_preferences

  private

  def array_preferences
    %i[preferred_styles preferred_colors disliked_colors].each do |attribute|
      errors.add(attribute, :invalid) unless public_send(attribute).is_a?(Array)
    end
  end

  def object_preferences
    %i[fit_preferences additional_preferences].each do |attribute|
      errors.add(attribute, :invalid) unless public_send(attribute).is_a?(Hash)
    end
  end
end
