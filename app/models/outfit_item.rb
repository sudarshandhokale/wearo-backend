class OutfitItem < ApplicationRecord
  belongs_to :outfit, inverse_of: :outfit_items
  belongs_to :clothing_item

  validates :role, inclusion: { in: OutfitTaxonomy.role_keys }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :clothing_item_id, uniqueness: { scope: :outfit_id }
  validates :position, uniqueness: { scope: :outfit_id }
  validate :clothing_item_belongs_to_outfit_user
  validate :role_matches_clothing_category
  validate :clothing_item_is_available, on: :create

  private

  def clothing_item_belongs_to_outfit_user
    return if outfit.blank? || clothing_item.blank? || outfit.user_id == clothing_item.user_id

    errors.add(:clothing_item, :invalid)
  end

  def role_matches_clothing_category
    return if role.blank? || clothing_item.blank? || clothing_item.category == role

    errors.add(:role, :invalid)
  end

  def clothing_item_is_available
    return if clothing_item.blank? || !clothing_item.discarded?

    errors.add(:clothing_item, :invalid)
  end
end
