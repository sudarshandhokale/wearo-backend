class AddGlobalGarmentMetadataToClothingItems < ActiveRecord::Migration[8.0]
  def change
    add_column :clothing_items, :garment_type, :string
    add_column :clothing_items, :cultural_tags, :jsonb, null: false, default: []
    add_index :clothing_items, [ :user_id, :garment_type ]
  end
end
