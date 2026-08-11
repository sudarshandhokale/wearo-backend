class CreateStyleProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :style_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :preferred_styles, null: false, default: []
      t.jsonb :preferred_colors, null: false, default: []
      t.jsonb :disliked_colors, null: false, default: []
      t.jsonb :fit_preferences, null: false, default: {}
      t.jsonb :additional_preferences, null: false, default: {}
      t.boolean :onboarding_completed, null: false, default: false

      t.timestamps
    end
  end
end
