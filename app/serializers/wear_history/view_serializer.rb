class WearHistory::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :worn_on, :occasion, :occasion_label, :context, :created_at

  labeled_attributes :occasion

  def context
    labeled_context(object.context)
  end

  def worn_on
    object.worn_on.iso8601
  end

  def created_at
    format_datetime_value(object.created_at)
  end
end
