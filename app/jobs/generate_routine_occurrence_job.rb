class GenerateRoutineOccurrenceJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(occurrence_id)
    Routines::GenerateOccurrence.call(RoutineOccurrence.find(occurrence_id))
  rescue ActiveRecord::RecordNotFound
    nil
  rescue StandardError => error
    Rails.logger.error("Routine occurrence generation failed for #{occurrence_id}: #{error.class}: #{error.message}")
  end
end
