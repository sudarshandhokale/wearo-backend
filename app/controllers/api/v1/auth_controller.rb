module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[
        register login confirm_email resend_confirmation forgot_password reset_password
      ]

      def register
        user = User.new(register_params)

        if user.save
          return complete_preview_registration(user) unless email_confirmation_required?

          AccountMailer.email_confirmation(user).deliver_later
          success_response(
            data: { message: I18n.t("auth.registration_pending_confirmation") },
            status: :created
          )
        else
          error_response(error: { message: I18n.t("auth.registration_failed"), details: user.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      def login
        user = User.find_by(email: auth_params[:email].to_s.downcase.strip)

        if user&.valid_password?(auth_params[:password]) && user.confirmed?
          update_trackable(user)
          set_authorization_header(user)
          success_response(data: user, serializer: User::SessionSerializer)
        elsif user&.valid_password?(auth_params[:password])
          error_response(error: { message: I18n.t("auth.email_not_confirmed") }, status: :forbidden)
        else
          error_response(error: { message: I18n.t("auth.invalid_login") }, status: :unauthorized)
        end
      end

      def confirm_email
        user = AccountTokens.verify_confirmation(params[:token].to_s)
        user.update!(confirmed_at: user.confirmed_at || Time.current)
        set_authorization_header(user)
        success_response(data: user, serializer: User::SessionSerializer)
      rescue AccountTokens::InvalidTokenError
        error_response(error: { message: I18n.t("auth.invalid_or_expired_token") }, status: :unprocessable_entity)
      end

      def resend_confirmation
        user = User.find_by(email: email_param)
        AccountMailer.email_confirmation(user).deliver_later if email_confirmation_required? && user.present? && !user.confirmed?
        success_response(data: { message: I18n.t("auth.confirmation_sent") }, status: :accepted)
      end

      def forgot_password
        user = User.find_by(email: email_param)
        AccountMailer.password_reset(user).deliver_later if email_delivery_enabled? && user.present?
        success_response(data: { message: I18n.t("auth.password_reset_sent") }, status: :accepted)
      end

      def reset_password
        user = AccountTokens.verify_password_reset(params[:token].to_s)
        if user.update(password_params)
          success_response(data: { message: I18n.t("auth.password_reset_completed") })
        else
          error_response(
            error: { message: I18n.t("auth.password_reset_failed"), details: user.errors.to_hash },
            status: :unprocessable_entity
          )
        end
      rescue AccountTokens::InvalidTokenError
        error_response(error: { message: I18n.t("auth.invalid_or_expired_token") }, status: :unprocessable_entity)
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
        params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :password,
          :password_confirmation,
          :timezone,
          :country_code,
          :preferred_city,
          :accept_terms,
          :accept_privacy,
          :accept_ai_processing,
          :confirm_adult
        )
      end

      def auth_params
        params.require(:user).permit(:email, :password)
      end

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end

      def email_param
        params.require(:user).permit(:email)[:email].to_s.downcase.strip
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

      def complete_preview_registration(user)
        user.update!(confirmed_at: Time.current)
        update_trackable(user)
        set_authorization_header(user)
        success_response(data: user, serializer: User::SessionSerializer, status: :created)
      end

      def email_confirmation_required?
        ActiveModel::Type::Boolean.new.cast(AppConfig.fetch(:email_confirmation_required, default: true))
      end

      def email_delivery_enabled?
        AppConfig.fetch(:email_delivery_method, default: "smtp") != "test"
      end
    end
  end
end
