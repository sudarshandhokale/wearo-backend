class CreateStylingPlanEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :styling_plan_entries do |t|
      t.references :styling_plan, null: false, foreign_key: true
      t.references :outfit, null: false, foreign_key: true
      t.date :planned_for, null: false
      t.jsonb :context, null: false, default: {}
      t.jsonb :weather_context, null: false, default: {}
      t.jsonb :events_context, null: false, default: []

      t.timestamps
    end

    add_index :styling_plan_entries, %i[styling_plan_id planned_for], unique: true
  end
end
