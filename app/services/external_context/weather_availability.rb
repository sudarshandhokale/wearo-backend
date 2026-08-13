module ExternalContext
  class WeatherAvailability
    class << self
      def call(result:, requested_date:, timezone:)
        return available if result.weather.present?

        unavailable(reason_for(result, requested_date, timezone))
      end

      private

      def available
        { "weather_status" => "available", "weather_status_label" => I18n.t("weather.status.available") }
      end

      def unavailable(reason)
        {
          "weather_status" => "unavailable",
          "weather_status_label" => I18n.t("weather.status.unavailable"),
          "weather_unavailable_reason" => reason,
          "weather_unavailable_message" => I18n.t("weather.unavailable.#{reason}")
        }
      end

      def reason_for(result, requested_date, timezone)
        return "location_missing" if result.city.blank?

        local_today = Time.current.in_time_zone(timezone).to_date
        return "outside_forecast_range" unless requested_date.between?(local_today, local_today + Weather::OpenMeteo::MAX_DAYS - 1)

        "provider_unavailable"
      end
    end
  end
end
