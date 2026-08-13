module Api
  module V1
    class RoutineOccurrencesController < BaseController
      def index
        start_at = Time.current
        occurrences = loaded_scope.where(scheduled_for: start_at..(start_at + 7.days)).chronological
        success_response(data: occurrences, serializer: RoutineOccurrence::ViewSerializer)
      end

      def today
        local_day = Time.current.in_time_zone(current_user.timezone).all_day
        occurrences = loaded_scope.where(scheduled_for: local_day).chronological
        success_response(data: occurrences, serializer: RoutineOccurrence::ViewSerializer)
      end

      private

      def loaded_scope
        current_user.routine_occurrences.includes(:styling_routine, outfit: Outfit.cover_media_includes)
      end
    end
  end
end
