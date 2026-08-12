class CreateOutfitFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :outfit_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :outfit, null: false, foreign_key: true
      t.string :reaction, null: false
      t.string :reason
      t.string :notes

      t.timestamps
    end

    add_index :outfit_feedbacks, %i[user_id outfit_id], unique: true
  end
end
