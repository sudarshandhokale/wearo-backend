module Api
  module V1
    class StylingRoutinesController < BaseController
      before_action :set_routine, only: %i[show update destroy]

      def index
        routines = current_user.styling_routines.recent_first
        success_response(data: routines, serializer: StylingRoutine::ViewSerializer)
      end

      def show
        success_response(data: @routine, serializer: StylingRoutine::ViewSerializer)
      end

      def create
        routine = current_user.styling_routines.new(routine_attributes_for_create)
        return routine_error(routine) unless routine.save

        Routines::ScheduleOccurrences.call(user: current_user)
        success_response(data: routine, serializer: StylingRoutine::ViewSerializer, status: :created)
      end

      def update
        return routine_error(@routine) unless @routine.update(routine_params)

        @routine.occurrences.scheduled.where("scheduled_for > ?", Time.current).destroy_all
        Routines::ScheduleOccurrences.call(user: current_user)
        success_response(data: @routine, serializer: StylingRoutine::ViewSerializer)
      end

      def destroy
        @routine.destroy!
        success_response(data: { message: I18n.t("routines.deleted") })
      end

      def drafts
        success_response(data: Routines::ParsePrompt.call(params[:prompt]))
      rescue Routines::ParsePrompt::InvalidPromptError
        error_response(error: { message: I18n.t("routines.invalid_prompt") }, status: :unprocessable_entity)
      end

      private

      def set_routine
        @routine = current_user.styling_routines.find(params[:id])
      end

      def routine_params
        params.require(:styling_routine).permit(
          :name, :routine_type, :local_time, :usage, :occasion, :activity, :city_mode, :city,
          :outfit_strategy, :recommendation_lead_minutes, :reminder_enabled, :active, days_of_week: []
        )
      end

      def routine_attributes_for_create
        routine_params.to_h.tap do |attributes|
          next if attributes.key?("recommendation_lead_minutes")

          attributes["recommendation_lead_minutes"] = Routines::RecommendationTiming.lead_minutes(attributes["local_time"])
        end
      end

      def routine_error(routine)
        error_response(error: { message: I18n.t("routines.save_failed"), details: routine.errors.to_hash }, status: :unprocessable_entity)
      end
    end
  end
end
