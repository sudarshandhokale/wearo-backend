class RecommendationRequest < ApplicationRecord
  belongs_to :user

  has_many :outfits, dependent: :nullify
  has_many :ai_requests, as: :trackable, dependent: :nullify

  enum :status, {
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, validate: true

  validates :prompt, presence: true, length: { maximum: 1_000 }
  validates :ranking_source, inclusion: { in: %w[ai deterministic] }, allow_nil: true
  validates :input_tokens, :output_tokens, :total_tokens, :attempt_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :structured_values

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def structured_values
    errors.add(:context, :invalid) unless context.is_a?(Hash)
    errors.add(:wardrobe_suggestions, :invalid) unless wardrobe_suggestions.is_a?(Array)
  end
end
