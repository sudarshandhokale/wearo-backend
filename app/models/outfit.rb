class Outfit < ApplicationRecord
  belongs_to :user

  has_many :outfit_items, -> { order(:position) }, dependent: :destroy, inverse_of: :outfit
  has_many :clothing_items, through: :outfit_items

  enum :status, {
    recommended: "recommended",
    worn: "worn",
    dismissed: "dismissed"
  }, validate: true

  validates :recommendation_score,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validate :structured_contexts_are_objects

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def structured_contexts_are_objects
    errors.add(:context, :invalid) unless context.is_a?(Hash)
    errors.add(:weather_context, :invalid) unless weather_context.is_a?(Hash)
  end
end
