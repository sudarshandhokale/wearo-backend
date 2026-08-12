class ClothingItem < ApplicationRecord
  belongs_to :user
  belongs_to :wardrobe
  has_many :ai_requests, as: :trackable, dependent: :nullify

  has_one_attached :image
  has_one_attached :polished_image
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
  validates :fit, inclusion: { in: ClothingTaxonomy.fit_keys }, allow_blank: true
  validates :formality_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :image, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 10.megabytes }
  validates :polished_image, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 20.megabytes }
  validate :wardrobe_belongs_to_user
  validate :image_is_unique_for_user
  validate :cultural_tags_are_an_array
  validate :ai_metadata_passes_guardrails

  before_validation :set_image_checksum

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

  def set_image_checksum
    self.image_checksum = image.attached? ? image.blob.checksum : nil
  end

  def image_is_unique_for_user
    return if discarded? || user_id.blank? || image_checksum.blank?

    duplicate_exists = self.class.active
      .where(user_id: user_id, image_checksum: image_checksum)
      .where.not(id: id)
      .exists?
    errors.add(:image, :taken) if duplicate_exists
  end

  def cultural_tags_are_an_array
    errors.add(:cultural_tags, :invalid) unless cultural_tags.is_a?(Array)
  end

  def ai_metadata_passes_guardrails
    Ai::Guardrails.model_text!(name, max_length: 120, allow_nil: true)
    Ai::Guardrails.model_text!(garment_type, max_length: 80, allow_nil: true)
    Ai::Guardrails.token!(fit, allow_nil: true)
    Ai::Guardrails.token_list!(secondary_colors, max_items: 8)
    Ai::Guardrails.token_list!(season_tags, max_items: 8)
    %i[occasion_tags style_tags cultural_tags].each do |attribute|
      Ai::Guardrails.token_list!(public_send(attribute))
    end
  rescue Ai::GuardrailViolationError
    errors.add(:base, :invalid)
  end

  def wardrobe_belongs_to_user
    return if wardrobe.blank? || user.blank? || wardrobe.user_id == user_id

    errors.add(:wardrobe, :invalid)
  end
end
