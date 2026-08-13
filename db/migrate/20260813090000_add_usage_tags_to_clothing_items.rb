class AddUsageTagsToClothingItems < ActiveRecord::Migration[8.0]
  def change
    add_column :clothing_items, :usage_tags, :jsonb, null: false, default: []
    add_column :clothing_items, :user_usage_tags, :jsonb
  end
end
