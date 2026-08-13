class OutfitFeedback::ViewSerializer < ApplicationSerializer
  attributes :id, :outfit_id, :reaction, :reaction_label, :reason, :reason_label, :notes, :created_at, :updated_at

  labeled_attributes :reaction, scope: :feedback_reaction
  labeled_attributes :reason, scope: :feedback_reason

  def created_at
    format_datetime_value(object.created_at)
  end

  def updated_at
    format_datetime_value(object.updated_at)
  end
end
