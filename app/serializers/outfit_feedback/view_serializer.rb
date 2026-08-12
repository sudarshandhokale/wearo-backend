class OutfitFeedback::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :reaction, :reason, :notes, :created_at, :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
