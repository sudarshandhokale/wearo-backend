class OutfitItem::ViewSerializer < ApplicationSerializer
  attributes :id,
             :clothing_item_id,
             :role,
             :role_label,
             :position,
             :clothing_item

  labeled_attributes :role, scope: :outfit_role

  def clothing_item
    ClothingItem::ViewSerializer.new(object.clothing_item).serializable_hash
  end
end
