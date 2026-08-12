class RestoreGenericEventContextColumns < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:styling_plans, :events_context)
      add_column :styling_plans, :events_context, :jsonb, null: false, default: []
    end
    unless column_exists?(:styling_plan_entries, :events_context)
      add_column :styling_plan_entries, :events_context, :jsonb, null: false, default: []
    end
  end
end
