class CreateOutfitVisualizations < ActiveRecord::Migration[8.0]
  def change
    create_table :outfit_visualizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :outfit, null: false, foreign_key: true
      t.string :mode, null: false, default: "flat_lay"
      t.string :status, null: false, default: "queued"
      t.string :provider
      t.string :model
      t.string :response_id
      t.jsonb :metadata, null: false, default: {}
      t.string :failure_code
      t.datetime :completed_at

      t.timestamps
    end

    add_index :outfit_visualizations, %i[user_id created_at]
    add_index :outfit_visualizations, %i[outfit_id status]
  end
end
