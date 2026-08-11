module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_user!

      def show
        success_response(data: { status: "ok" })
      end
    end
  end
end
