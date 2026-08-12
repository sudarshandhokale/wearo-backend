class StylingPlanEntry::ViewSerializer < ApplicationSerializer
  attributes :id, :planned_for, :context, :weather_context, :events_context, :outfit

  def planned_for
    object.planned_for.iso8601
  end

  def outfit
    Outfit::ViewSerializer.new(object.outfit).serializable_hash
  end
end
