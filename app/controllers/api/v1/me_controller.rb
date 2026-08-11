module Api
  module V1
    class MeController < BaseController
      def show
        success_response(data: current_user, serializer: User::ProfileSerializer)
      end

      def update
        if current_user.update(me_params)
          success_response(data: current_user, serializer: User::ProfileSerializer)
        else
          error_response(error: { message: I18n.t("profile.update_failed"), details: current_user.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      private

      def me_params
        params.require(:user).permit(:first_name, :last_name, :timezone, :country_code, :preferred_city)
      end
    end
  end
end
