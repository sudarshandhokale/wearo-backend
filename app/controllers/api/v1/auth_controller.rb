module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[register login]

      def register
        user = User.new(register_params)

        if user.save
          set_authorization_header(user)
          success_response(data: user, serializer: User::SessionSerializer, status: :created)
        else
          error_response(error: { message: I18n.t("auth.registration_failed"), details: user.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      def login
        user = User.find_by(email: auth_params[:email].to_s.downcase.strip)

        if user&.valid_password?(auth_params[:password])
          update_trackable(user)
          set_authorization_header(user)
          success_response(data: user, serializer: User::SessionSerializer)
        else
          error_response(error: { message: I18n.t("auth.invalid_login") }, status: :unauthorized)
        end
      end

      def refresh
        set_authorization_header(current_user)
        success_response(data: { message: I18n.t("auth.token_refreshed") })
      end

      def logout
        Auth::Token.revoke(bearer_token)
        success_response(data: { message: I18n.t("auth.logged_out") })
      end

      private

      def register_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :timezone, :country_code, :preferred_city)
      end

      def auth_params
        params.require(:user).permit(:email, :password)
      end

      def update_trackable(user)
        user.update(
          sign_in_count: user.sign_in_count + 1,
          current_sign_in_at: Time.current,
          last_sign_in_at: user.current_sign_in_at,
          current_sign_in_ip: request.remote_ip,
          last_sign_in_ip: user.current_sign_in_ip
        )
      end

      def set_authorization_header(user)
        response.set_header("Authorization", "Bearer #{Auth::Token.encode(user)}")
      end
    end
  end
end
