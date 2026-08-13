class ApplicationSerializer < ActiveModel::Serializer
  def self.labeled_attributes(*attributes, scope: nil)
    attributes.each do |attribute_name|
      attribute "#{attribute_name}_label".to_sym
      define_method("#{attribute_name}_label") do
        Metadata::Labels.for(object.public_send(attribute_name), scope: scope || attribute_name)
      end
    end
  end

  def format_datetime_value(value)
    return value if value.blank? || !value.respond_to?(:in_time_zone)

    value.utc.iso8601
  end

  def labeled_context(value)
    Metadata::Labels.context(value)
  end
end
