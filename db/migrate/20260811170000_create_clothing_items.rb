class CreateClothingItems < ActiveRecord::Migration[8.0]
  def change
    create_table :clothing_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wardrobe, null: false, foreign_key: true
      t.string :name
      t.string :category
      t.string :subcategory
      t.string :primary_color
      t.jsonb :secondary_colors, null: false, default: []
      t.string :pattern
      t.string :material
      t.jsonb :season_tags, null: false, default: []
      t.jsonb :occasion_tags, null: false, default: []
      t.jsonb :style_tags, null: false, default: []
      t.integer :formality_score
      t.string :status, null: false, default: "uploaded"
      t.jsonb :ai_metadata, null: false, default: {}
      t.datetime :ai_analyzed_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :clothing_items, [ :user_id, :status ]
    add_index :clothing_items, [ :user_id, :category ]
    add_index :clothing_items, [ :user_id, :primary_color ]
    add_index :clothing_items, :discarded_at
  end
end
