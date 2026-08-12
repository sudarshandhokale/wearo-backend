module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def require_ai_processing_consent!
        return if current_user.ai_processing_consented?

        error_response(error: { message: I18n.t("consent.ai_processing_required") }, status: :forbidden)
      end
    end
  end
end
