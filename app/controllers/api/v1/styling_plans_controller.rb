module Api
  module V1
    class StylingPlansController < BaseController
      before_action :set_styling_plan, only: :show

      def index
        plans = current_user.styling_plans.recent_first.page(params[:page]).per(per_page)
        success_response(
          data: ActiveModelSerializers::SerializableResource.new(plans, each_serializer: StylingPlan::ViewSerializer),
          meta: pagination_meta(plans)
        )
      end

      def show
        success_response(data: @styling_plan, serializer: StylingPlan::ViewSerializer)
      end

      def create
        plan = StylingPlans::Generate.call(user: current_user, attributes: styling_plan_params)
        plan = loaded_scope.find(plan.id)
        success_response(data: plan, serializer: StylingPlan::ViewSerializer, status: :created)
      rescue StylingPlans::InvalidDateRangeError, ExternalContext::InvalidDateRangeError
        error_response(error: { message: I18n.t("styling_plans.invalid_date_range") }, status: :unprocessable_entity)
      rescue ActiveRecord::RecordInvalid => error
        error_response(
          error: { message: I18n.t("styling_plans.create_failed"), details: error.record.errors.to_hash },
          status: :unprocessable_entity
        )
      rescue Stylist::InsufficientWardrobeError => error
        error_response(
          error: {
            message: I18n.t("stylist.insufficient_wardrobe"),
            details: { missing_roles: error.missing_roles, required_combinations: error.required_combinations }
          },
          status: :unprocessable_entity
        )
      end

      private

      def set_styling_plan
        @styling_plan = loaded_scope.find(params[:id])
      end

      def loaded_scope
        current_user.styling_plans.includes(entries: { outfit: Outfit.cover_media_includes })
      end

      def styling_plan_params
        params.require(:styling_plan).permit(:plan_type, :city, :start_date, :end_date, :prompt)
      end

      def per_page
        [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 50 ].min
      end
    end
  end
end
