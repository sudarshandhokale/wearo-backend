class CreateStylingPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :styling_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan_type, null: false
      t.string :status, null: false, default: "processing"
      t.string :city
      t.string :country_code
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :prompt
      t.jsonb :weather_context, null: false, default: []
      t.jsonb :events_context, null: false, default: []
      t.jsonb :packing_summary, null: false, default: {}
      t.string :failure_code
      t.datetime :completed_at

      t.timestamps
    end

    add_index :styling_plans, %i[user_id start_date]
    add_index :styling_plans, %i[user_id status]
  end
end
