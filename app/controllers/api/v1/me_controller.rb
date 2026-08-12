module Api
  module V1
    class MeController < BaseController
      def show
        success_response(data: current_user, serializer: User::ProfileSerializer)
      end

      def update
        if full_body_image_upload? && !full_body_image_consent?
          return error_response(error: { message: I18n.t("consent.full_body_image_required") }, status: :forbidden)
        end

        current_user.full_body_image_consent_at ||= Time.current if full_body_image_upload?
        if current_user.update(me_params.except(:full_body_image_consent))
          success_response(data: current_user, serializer: User::ProfileSerializer)
        else
          error_response(error: { message: I18n.t("profile.update_failed"), details: current_user.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      def destroy
        Accounts::Erase.call(
          user: current_user,
          password: deletion_params[:password],
          confirmation: deletion_params[:confirmation]
        )
        success_response(data: { message: I18n.t("profile.account_deleted") })
      rescue Accounts::InvalidPasswordError
        error_response(error: { message: I18n.t("profile.invalid_password") }, status: :unauthorized)
      rescue Accounts::InvalidDeletionConfirmationError
        error_response(error: { message: I18n.t("profile.invalid_deletion_confirmation") }, status: :unprocessable_entity)
      end

      def destroy_full_body_image
        current_user.full_body_image.purge if current_user.full_body_image.attached?
        current_user.update!(full_body_image_consent_at: nil)
        success_response(data: { message: I18n.t("profile.full_body_image_deleted") })
      end

      def update_consents
        current_user.record_current_consents!(consent_params)
        success_response(data: current_user, serializer: User::ProfileSerializer)
      end

      def export
        payload = Accounts::Export.call(user: current_user)
        send_data JSON.pretty_generate(payload),
                  type: "application/json",
                  disposition: :attachment,
                  filename: "wearo-data-export-#{Time.current.to_date.iso8601}.json"
      end

      private

      def me_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :timezone,
          :country_code,
          :preferred_city,
          :full_body_image,
          :full_body_image_consent
        )
      end

      def deletion_params
        params.require(:account).permit(:password, :confirmation)
      end

      def full_body_image_upload?
        me_params[:full_body_image].present?
      end

      def full_body_image_consent?
        ActiveModel::Type::Boolean.new.cast(me_params[:full_body_image_consent])
      end

      def consent_params
        params.require(:consents).permit(:accept_terms, :accept_privacy, :accept_ai_processing, :confirm_adult)
      end
    end
  end
end
