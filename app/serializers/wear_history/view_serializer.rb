class WearHistory::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :worn_on, :occasion, :context, :created_at

  def worn_on
    object.worn_on.iso8601
  end

  def created_at
    format_datetime_value(object.created_at)
  end
end
