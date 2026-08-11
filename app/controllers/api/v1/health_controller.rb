module Api
  module V1
    class HealthController < BaseController
      def show
        success_response(data: { status: "ok" })
      end
    end
  end
end
