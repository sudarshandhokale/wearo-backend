module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_user!

      def show
        success_response(data: { status: "ok" })
      end

      def readiness
        checks = readiness_checks
        status = checks.values.all? { |value| value == "ok" } ? :ok : :service_unavailable
        render json: {
          success: status == :ok,
          data: { status: status == :ok ? "ready" : "not_ready", checks: checks },
          meta: nil
        }, status: status
      end

      private

      def readiness_checks
        {
          database: database_ready? ? "ok" : "unavailable",
          redis: redis_ready? ? "ok" : "unavailable",
          storage: storage_ready? ? "ok" : "misconfigured",
          workers: workers_ready? ? "ok" : "unavailable"
        }
      end

      def database_ready?
        ActiveRecord::Base.connection.select_value("SELECT 1") == 1
      rescue StandardError
        false
      end

      def redis_ready?
        Redis.new(url: AppConfig.fetch(:redis_url, default: "redis://localhost:6379/0")).ping == "PONG"
      rescue StandardError
        false
      end

      def storage_ready?
        return true unless Rails.env.production?

        Rails.application.config.active_storage.service == :amazon && AppConfig.fetch(:aws_storage_bucket).present?
      end

      def workers_ready?
        return true unless Rails.env.production?

        require "sidekiq/api"
        Sidekiq::ProcessSet.new.size.positive?
      rescue StandardError
        false
      end
    end
  end
end
