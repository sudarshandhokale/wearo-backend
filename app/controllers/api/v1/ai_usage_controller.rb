module Api
  module V1
    class AiUsageController < BaseController
      def show
        success_response(data: Ai::UsageTracker.daily_summary(current_user))
      end
    end
  end
end
