class OutfitItem::ViewSerializer < ApplicationSerializer
  attributes :id,
             :clothing_item_id,
             :role,
             :position,
             :clothing_item

  def clothing_item
    ClothingItem::ViewSerializer.new(object.clothing_item).serializable_hash
  end
end
