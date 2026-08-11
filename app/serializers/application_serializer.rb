class ApplicationSerializer < ActiveModel::Serializer
  def format_datetime_value(value)
    return value if value.blank? || !value.respond_to?(:in_time_zone)

    value.utc.iso8601
  end
end
