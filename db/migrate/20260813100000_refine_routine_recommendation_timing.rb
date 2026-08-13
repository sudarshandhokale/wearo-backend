class RefineRoutineRecommendationTiming < ActiveRecord::Migration[8.0]
  def up
    change_column_default :styling_routines, :recommendation_lead_minutes, from: 720, to: 60
    execute <<~SQL.squish
      UPDATE styling_routines
      SET recommendation_lead_minutes = CASE
        WHEN EXTRACT(HOUR FROM local_time) < 12
          THEN (EXTRACT(HOUR FROM local_time)::integer * 60) + EXTRACT(MINUTE FROM local_time)::integer + 240
        ELSE 60
      END
      WHERE recommendation_lead_minutes = 720
    SQL
  end

  def down
    change_column_default :styling_routines, :recommendation_lead_minutes, from: 60, to: 720
  end
end
