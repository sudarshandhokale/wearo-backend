class StylingPlanEntry < ApplicationRecord
  belongs_to :styling_plan, inverse_of: :entries
  belongs_to :outfit

  validates :planned_for, presence: true, uniqueness: { scope: :styling_plan_id }
  validate :structured_values
  validate :outfit_belongs_to_plan_user

  private

  def structured_values
    errors.add(:context, :invalid) unless context.is_a?(Hash)
    errors.add(:weather_context, :invalid) unless weather_context.is_a?(Hash)
    errors.add(:events_context, :invalid) unless events_context.is_a?(Array)
  end

  def outfit_belongs_to_plan_user
    return if outfit.blank? || styling_plan.blank? || outfit.user_id == styling_plan.user_id

    errors.add(:outfit, :invalid)
  end
end
