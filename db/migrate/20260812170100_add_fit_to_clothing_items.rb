class AddFitToClothingItems < ActiveRecord::Migration[8.0]
  def change
    add_column :clothing_items, :fit, :string
    add_index :clothing_items, %i[user_id fit]
  end
end
