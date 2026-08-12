class Outfit < ApplicationRecord
  belongs_to :user
  belongs_to :recommendation_request, optional: true

  has_many :outfit_items, -> { order(:position) }, dependent: :destroy, inverse_of: :outfit
  has_many :clothing_items, through: :outfit_items
  has_many :wear_histories, dependent: :destroy
  has_one :outfit_feedback, dependent: :destroy
  has_many :outfit_visualizations, dependent: :destroy

  enum :status, {
    recommended: "recommended",
    saved: "saved",
    worn: "worn",
    dismissed: "dismissed"
  }, validate: true

  validates :recommendation_score,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
  validates :name, length: { maximum: 60 }, allow_blank: true
  validates :feedback_note, length: { maximum: 500 }, allow_nil: true
  validate :structured_contexts_are_objects
  validate :name_passes_guardrails

  scope :recent_first, -> { order(created_at: :desc) }

  def self.cover_media_includes
    {
      outfit_visualizations: { image_attachment: :blob },
      outfit_items: {
        clothing_item: [ { image_attachment: :blob }, { polished_image_attachment: :blob } ]
      }
    }
  end

  private

  def name_passes_guardrails
    Ai::Guardrails.model_text!(name, max_length: 60, allow_nil: true)
  rescue Ai::GuardrailViolationError
    errors.add(:name, :invalid)
  end

  def structured_contexts_are_objects
    errors.add(:context, :invalid) unless context.is_a?(Hash)
    errors.add(:weather_context, :invalid) unless weather_context.is_a?(Hash)
    errors.add(:score_breakdown, :invalid) unless score_breakdown.is_a?(Hash)
  end
end
