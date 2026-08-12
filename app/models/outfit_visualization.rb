class OutfitVisualization < ApplicationRecord
  belongs_to :user
  belongs_to :outfit
  has_one_attached :reference_image
  has_one_attached :image
  has_many :ai_requests, as: :trackable, dependent: :nullify

  enum :mode, { flat_lay: "flat_lay", try_on: "try_on" }, validate: true
  enum :status, { queued: "queued", processing: "processing", ready: "ready", failed: "failed" }, validate: true

  validates :reference_image, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 10.megabytes }
  validates :image, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 20.megabytes }
  validate :outfit_belongs_to_user
  validate :reference_image_required_for_try_on
  validate :outfit_has_source_images
  validate :metadata_is_an_object

  scope :recent_first, -> { order(created_at: :desc) }

  def person_reference_image
    return reference_image if reference_image.attached?

    user.full_body_image
  end

  private

  def outfit_belongs_to_user
    return if outfit.blank? || user.blank? || outfit.user_id == user_id

    errors.add(:outfit, :invalid)
  end

  def reference_image_required_for_try_on
    errors.add(:reference_image, :blank) if try_on? && !person_reference_image.attached?
  end

  def metadata_is_an_object
    errors.add(:metadata, :invalid) unless metadata.is_a?(Hash)
  end

  def outfit_has_source_images
    return if outfit.blank? || outfit.clothing_items.any? { |item| item.image.attached? }

    errors.add(:outfit, :missing_images)
  end
end
