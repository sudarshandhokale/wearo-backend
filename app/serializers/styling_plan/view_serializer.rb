class StylingPlan::ViewSerializer < ApplicationSerializer
  attributes :id, :plan_type, :status, :city, :country_code, :start_date, :end_date, :prompt,
             :weather_context, :events_context, :packing_summary, :failure_code, :completed_at,
             :entries, :created_at, :updated_at

  def start_date
    object.start_date.iso8601
  end

  def end_date
    object.end_date.iso8601
  end

  def completed_at
    format_datetime_value(object.completed_at)
  end

  def entries
    return [] unless object.association(:entries).loaded?

    object.entries.map { |entry| StylingPlanEntry::ViewSerializer.new(entry).serializable_hash }
  end

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
