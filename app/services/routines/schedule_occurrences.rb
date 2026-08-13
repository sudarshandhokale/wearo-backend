module Routines
  class ScheduleOccurrences
    class << self
      def call(now: Time.current, horizon: 24.hours, user: nil)
        scope = user ? user.styling_routines : StylingRoutine.all
        occurrences = scope.active.includes(:user).find_each.flat_map do |scheduled_routine|
          occurrences_for(scheduled_routine, now: now, horizon: horizon).map do |scheduled_for|
            find_or_create_occurrence(scheduled_routine, scheduled_for)
          end
        end

        occurrences.group_by(&:user_id).each_value do |user_occurrences|
          sorted_occurrences = user_occurrences.sort_by(&:scheduled_for)
          sorted_occurrences.each_with_index do |occurrence, index|
            previous = sorted_occurrences[index - 1] if index.positive?
            next if combined_with_previous?(previous, occurrence)

            enqueue_generation(occurrence) if due?(occurrence, now)
          end
        end
      end

      private

      def find_or_create_occurrence(routine, scheduled_for)
        routine.occurrences.find_or_create_by!(scheduled_for: scheduled_for) { |record| record.user = routine.user }
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        routine.occurrences.find_by!(scheduled_for: scheduled_for)
      end

      def occurrences_for(routine, now:, horizon:)
        zone = ActiveSupport::TimeZone[routine.user.timezone] || ActiveSupport::TimeZone["UTC"]
        local_start = now.in_time_zone(zone)
        local_end = (now + horizon).in_time_zone(zone)

        (local_start.to_date..local_end.to_date).filter_map do |date|
          next unless routine.days_of_week.include?(date.cwday)

          zone.local(date.year, date.month, date.day, routine.local_time.hour, routine.local_time.min)
        end.select { |time| time.between?(now - 1.minute, now + horizon) }
      end

      def due?(occurrence, now)
        occurrence.scheduled? &&
          occurrence.scheduled_for <= now + occurrence.styling_routine.recommendation_lead_minutes.minutes
      end

      def enqueue_generation(occurrence)
        claimed = RoutineOccurrence.where(id: occurrence.id, status: "scheduled").update_all(
          status: "queued", updated_at: Time.current
        )
        return unless claimed == 1

        GenerateRoutineOccurrenceJob.perform_later(occurrence.id)
      rescue StandardError
        occurrence.update_columns(status: "scheduled", updated_at: Time.current)
        raise
      end

      def combined_with_previous?(previous, occurrence)
        previous && previous.user_id == occurrence.user_id &&
          previous.styling_routine.outfit_strategy == "combine_with_next" &&
          occurrence.scheduled_for <= previous.scheduled_for + 4.hours
      end
    end
  end
end
