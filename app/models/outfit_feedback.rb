class OutfitFeedback < ApplicationRecord
  REASONS = %w[
    too_formal too_casual dont_like_colors recently_worn not_comfortable
    not_my_style other
  ].freeze

  belongs_to :user
  belongs_to :outfit

  enum :reaction, { liked: "liked", disliked: "disliked" }, validate: true

  validates :outfit_id, uniqueness: { scope: :user_id }
  validates :reason, inclusion: { in: REASONS }, allow_nil: true
  validates :notes, length: { maximum: 500 }, allow_nil: true
  validate :outfit_belongs_to_user

  private

  def outfit_belongs_to_user
    return if outfit.blank? || user.blank? || outfit.user_id == user_id

    errors.add(:outfit, :invalid)
  end
end
