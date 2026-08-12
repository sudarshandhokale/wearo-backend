class StylingPlan < ApplicationRecord
  MAX_DAYS = 16

  belongs_to :user
  has_many :entries, -> { order(:planned_for) }, class_name: "StylingPlanEntry", dependent: :destroy, inverse_of: :styling_plan
  has_many :outfits, through: :entries

  enum :plan_type, { week: "week", vacation: "vacation" }, validate: true
  enum :status, { processing: "processing", completed: "completed", failed: "failed" }, validate: true

  validates :start_date, :end_date, presence: true
  validates :city, length: { maximum: 120 }, allow_nil: true
  validates :country_code, length: { is: 2 }, allow_nil: true
  validates :prompt, length: { maximum: 1_000 }, allow_nil: true
  validate :date_range_is_valid
  validate :structured_values

  scope :recent_first, -> { order(start_date: :desc, created_at: :desc) }

  private

  def date_range_is_valid
    return if start_date.blank? || end_date.blank?

    days = (end_date - start_date).to_i + 1
    errors.add(:end_date, :invalid) unless days.between?(1, MAX_DAYS)
  end

  def structured_values
    errors.add(:weather_context, :invalid) unless weather_context.is_a?(Array)
    errors.add(:events_context, :invalid) unless events_context.is_a?(Array)
    errors.add(:packing_summary, :invalid) unless packing_summary.is_a?(Hash)
  end
end
