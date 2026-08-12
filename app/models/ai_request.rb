class AiRequest < ApplicationRecord
  OPERATIONS = %w[clothing_analysis stylist_recommendation].freeze

  belongs_to :user
  belongs_to :trackable, polymorphic: true, optional: true

  enum :status, {
    pending: "pending",
    succeeded: "succeeded",
    failed: "failed"
  }, validate: true

  validates :operation, inclusion: { in: OPERATIONS }
  validates :reserved_tokens, :input_tokens, :output_tokens, :total_tokens, :attempt_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :created_today, -> { where(created_at: Time.current.all_day) }
end
