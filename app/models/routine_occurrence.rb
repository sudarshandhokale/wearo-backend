class RoutineOccurrence < ApplicationRecord
  belongs_to :user
  belongs_to :styling_routine
  belongs_to :outfit, optional: true

  enum :status, {
    scheduled: "scheduled", queued: "queued", generating: "generating",
    generated: "generated", skipped: "skipped", failed: "failed"
  }, validate: true

  validates :scheduled_for, presence: true, uniqueness: { scope: :styling_routine_id }
  validate :routine_belongs_to_user

  scope :chronological, -> { order(:scheduled_for) }

  private

  def routine_belongs_to_user
    return if styling_routine.blank? || user.blank? || styling_routine.user_id == user_id

    errors.add(:styling_routine, :invalid)
  end
end
