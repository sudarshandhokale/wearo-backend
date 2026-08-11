class Wardrobe::ViewSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :created_at,
             :updated_at

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
