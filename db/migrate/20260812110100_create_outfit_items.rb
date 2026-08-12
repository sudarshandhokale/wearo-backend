class CreateOutfitItems < ActiveRecord::Migration[8.0]
  def change
    create_table :outfit_items do |t|
      t.references :outfit, null: false, foreign_key: true
      t.references :clothing_item, null: false, foreign_key: true
      t.string :role, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :outfit_items, [ :outfit_id, :clothing_item_id ], unique: true
    add_index :outfit_items, [ :outfit_id, :position ], unique: true
  end
end
