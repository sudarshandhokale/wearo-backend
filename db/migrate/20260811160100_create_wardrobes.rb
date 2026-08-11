class CreateWardrobes < ActiveRecord::Migration[8.0]
  def change
    create_table :wardrobes do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false, default: "My Wardrobe"

      t.timestamps
    end
  end
end
