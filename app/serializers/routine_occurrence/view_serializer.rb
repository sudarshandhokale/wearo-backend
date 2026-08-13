class RoutineOccurrence::ViewSerializer < ApplicationSerializer
  attributes :id, :styling_routine_id, :scheduled_for, :status, :status_label, :context,
             :weather_context, :suggestions, :failure_code, :failure_message, :generated_at,
             :routine, :outfit, :created_at, :updated_at

  labeled_attributes :status, scope: :routine_occurrence_status

  def scheduled_for = format_datetime_value(object.scheduled_for)
  def generated_at = format_datetime_value(object.generated_at)
  def created_at = format_datetime_value(object.created_at)
  def updated_at = format_datetime_value(object.updated_at)
  def context = labeled_context(object.context)
  def weather_context = Metadata::Labels.weather(object.weather_context)
  def suggestions = object.suggestions.map { |suggestion| Metadata::Labels.suggestion(suggestion) }
  def routine = StylingRoutine::ViewSerializer.new(object.styling_routine).serializable_hash

  def outfit
    Outfit::ViewSerializer.new(object.outfit).serializable_hash if object.outfit
  end

  def failure_message
    return unless object.failed?

    I18n.t("routines.failures.#{object.failure_code}", default: I18n.t("routines.failures.generation_failed"))
  end
end
