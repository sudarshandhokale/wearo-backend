class CreateStylingRoutinesAndOccurrences < ActiveRecord::Migration[8.0]
  def change
    create_table :styling_routines do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :routine_type, null: false
      t.jsonb :days_of_week, null: false, default: []
      t.time :local_time, null: false
      t.string :usage, null: false
      t.string :occasion
      t.string :activity
      t.string :city_mode, null: false, default: "profile"
      t.string :city
      t.string :outfit_strategy, null: false, default: "separate"
      t.integer :recommendation_lead_minutes, null: false, default: 720
      t.boolean :reminder_enabled, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :styling_routines, %i[user_id active]

    create_table :routine_occurrences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :styling_routine, null: false, foreign_key: true
      t.references :outfit, foreign_key: true
      t.datetime :scheduled_for, null: false
      t.string :status, null: false, default: "scheduled"
      t.jsonb :context, null: false, default: {}
      t.jsonb :weather_context, null: false, default: {}
      t.jsonb :suggestions, null: false, default: []
      t.string :failure_code
      t.datetime :generated_at
      t.timestamps
    end
    add_index :routine_occurrences, %i[styling_routine_id scheduled_for], unique: true, name: "index_routine_occurrences_on_routine_and_schedule"
    add_index :routine_occurrences, %i[user_id scheduled_for]
    add_index :routine_occurrences, %i[status scheduled_for]
  end
end
