class ClothingItem < ApplicationRecord
  belongs_to :user
  belongs_to :wardrobe

  has_one_attached :image
  has_many :outfit_items, dependent: :destroy
  has_many :outfits, through: :outfit_items

  enum :status, {
    uploaded: "uploaded",
    processing: "processing",
    ready: "ready",
    analysis_failed: "analysis_failed"
  }, validate: true

  validates :wardrobe, presence: true
  validates :category, inclusion: { in: ClothingTaxonomy.category_keys }, allow_blank: true
  validates :subcategory, inclusion: { in: ->(item) { ClothingTaxonomy.subcategory_keys(item.category) } }, allow_blank: true
  validates :formality_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :image, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 10.megabytes }
  validate :wardrobe_belongs_to_user

  scope :active, -> { where(discarded_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  def discarded?
    discarded_at.present?
  end

  def discard!
    update!(discarded_at: Time.current)
  end

  def mark_processing!
    update!(
      status: :processing,
      ai_analyzed_at: nil,
      ai_metadata: ai_metadata.except("error")
    )
  end

  private

  def wardrobe_belongs_to_user
    return if wardrobe.blank? || user.blank? || wardrobe.user_id == user_id

    errors.add(:wardrobe, :invalid)
  end
end
