module Api
  module V1
    class StylistController < BaseController
      before_action :require_ai_processing_consent!

      def recommendations
        if Routines::DetectIntent.recurring?(params[:prompt])
          return routine_draft_response
        end

        result = Stylist::Recommend.call(
          user: current_user,
          prompt: params[:prompt]
        )
        success_response(data: result, serializer: Stylist::RecommendationSerializer, status: :created)
      rescue Stylist::InvalidPromptError
        error_response(error: { message: I18n.t("stylist.invalid_prompt") }, status: :unprocessable_entity)
      rescue Stylist::RecommendationLimitError
        error_response(error: { message: I18n.t("stylist.recommendation_limit_reached") }, status: :too_many_requests)
      rescue Stylist::InsufficientWardrobeError => error
        error_response(
          error: {
            message: I18n.t("stylist.insufficient_wardrobe"),
            details: {
              missing_roles: error.missing_roles,
              required_combinations: error.required_combinations
            }
          },
          status: :unprocessable_entity
        )
      rescue Routines::ParsePrompt::InvalidPromptError
        error_response(error: { message: I18n.t("routines.invalid_prompt") }, status: :unprocessable_entity)
      end

      private

      def routine_draft_response
        success_response(
          data: {
            intent: "recurring_routine",
            requires_confirmation: true,
            message: I18n.t("routines.confirm_drafts"),
            routine_drafts: Routines::ParsePrompt.call(params[:prompt])
          }
        )
      end
    end
  end
end
