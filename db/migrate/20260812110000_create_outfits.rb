class CreateOutfits < ActiveRecord::Migration[8.0]
  def change
    create_table :outfits do |t|
      t.references :user, null: false, foreign_key: true
      t.text :prompt
      t.string :occasion
      t.jsonb :context, null: false, default: {}
      t.jsonb :weather_context, null: false, default: {}
      t.decimal :recommendation_score, precision: 5, scale: 2
      t.text :explanation
      t.string :status, null: false, default: "recommended"
      t.datetime :recommended_for

      t.timestamps
    end

    add_index :outfits, [ :user_id, :created_at ]
    add_index :outfits, [ :user_id, :status ]
    add_index :outfits, :recommended_for
  end
end
