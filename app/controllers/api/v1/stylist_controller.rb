module Api
  module V1
    class StylistController < BaseController
      def recommendations
        result = Stylist::Recommend.call(user: current_user, prompt: params[:prompt])
        success_response(data: result, serializer: Stylist::RecommendationSerializer, status: :created)
      rescue Stylist::InvalidPromptError
        error_response(error: { message: I18n.t("stylist.invalid_prompt") }, status: :unprocessable_entity)
      rescue Stylist::InsufficientWardrobeError => error
        error_response(
          error: {
            message: I18n.t("stylist.insufficient_wardrobe"),
            details: { missing_roles: error.missing_roles }
          },
          status: :unprocessable_entity
        )
      end
    end
  end
end
