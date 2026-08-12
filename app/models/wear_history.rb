class WearHistory < ApplicationRecord
  belongs_to :user
  belongs_to :outfit

  validates :worn_on, presence: true, uniqueness: { scope: %i[user_id outfit_id] }
  validates :occasion, length: { maximum: 80 }, allow_nil: true
  validate :context_is_an_object
  validate :outfit_belongs_to_user

  scope :recent_first, -> { order(worn_on: :desc, created_at: :desc) }

  private

  def context_is_an_object
    errors.add(:context, :invalid) unless context.is_a?(Hash)
  end

  def outfit_belongs_to_user
    return if outfit.blank? || user.blank? || outfit.user_id == user_id

    errors.add(:outfit, :invalid)
  end
end
