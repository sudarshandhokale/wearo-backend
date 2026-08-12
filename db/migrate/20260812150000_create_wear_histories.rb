class CreateWearHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :wear_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :outfit, null: false, foreign_key: true
      t.date :worn_on, null: false
      t.string :occasion
      t.jsonb :context, null: false, default: {}

      t.timestamps
    end

    add_index :wear_histories, %i[user_id outfit_id worn_on], unique: true
    add_index :wear_histories, %i[user_id worn_on]
  end
end
