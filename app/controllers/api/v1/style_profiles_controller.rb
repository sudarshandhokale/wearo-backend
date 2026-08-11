module Api
  module V1
    class StyleProfilesController < BaseController
      def show
        success_response(data: style_profile, serializer: StyleProfile::ViewSerializer)
      end

      def update
        if style_profile.update(style_profile_params)
          success_response(data: style_profile, serializer: StyleProfile::ViewSerializer)
        else
          error_response(error: { message: I18n.t("style_profile.update_failed"), details: style_profile.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      private

      def style_profile
        @style_profile ||= current_user.style_profile || current_user.create_style_profile!
      end

      def style_profile_params
        params.require(:style_profile).permit(
          :onboarding_completed,
          preferred_styles: [],
          preferred_colors: [],
          disliked_colors: [],
          fit_preferences: {},
          additional_preferences: {}
        )
      end
    end
  end
end
