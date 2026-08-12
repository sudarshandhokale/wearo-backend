module ExternalContext
  module Weather
    class OpenMeteo
      GEOCODING_ENDPOINT = "https://geocoding-api.open-meteo.com/v1/search"
      FORECAST_ENDPOINT = "https://api.open-meteo.com/v1/forecast"
      MAX_DAYS = 16

      def initialize(client: External::JsonClient.new)
        @client = client
      end

      def call(city:, country_code: nil, start_date: Date.current, end_date: start_date)
        location = geocode(city, country_code)
        return [] if location.blank?

        payload = @client.get(endpoint: forecast_uri(location, start_date, end_date))
        normalize_daily(payload.fetch("daily", {}))
      rescue External::Error, KeyError, TypeError
        []
      end

      private

      def geocode(city, country_code)
        payload = @client.get(endpoint: URI("#{GEOCODING_ENDPOINT}?#{URI.encode_www_form(
          name: city.to_s.first(120), count: 10, language: "en", format: "json"
        )}"))
        results = Array(payload["results"])
        results.find { |result| country_code.blank? || result["country_code"] == country_code.upcase } || results.first
      end

      def forecast_uri(location, start_date, end_date)
        query = {
          latitude: location.fetch("latitude"),
          longitude: location.fetch("longitude"),
          timezone: "auto",
          start_date: start_date.iso8601,
          end_date: end_date.iso8601,
          daily: %w[
            weather_code temperature_2m_max temperature_2m_min apparent_temperature_max
            apparent_temperature_min precipitation_probability_max wind_speed_10m_max
          ].join(",")
        }
        URI("#{FORECAST_ENDPOINT}?#{URI.encode_www_form(query)}")
      end

      def normalize_daily(daily)
        Array(daily["time"]).each_index.map do |index|
          {
            "date" => daily["time"][index],
            "condition" => condition(daily["weather_code"]&.[](index)),
            "temperature_max_c" => daily["temperature_2m_max"]&.[](index),
            "temperature_min_c" => daily["temperature_2m_min"]&.[](index),
            "apparent_temperature_max_c" => daily["apparent_temperature_max"]&.[](index),
            "apparent_temperature_min_c" => daily["apparent_temperature_min"]&.[](index),
            "precipitation_probability" => daily["precipitation_probability_max"]&.[](index),
            "wind_speed_max_kmh" => daily["wind_speed_10m_max"]&.[](index)
          }.compact
        end
      end

      def condition(code)
        value = Integer(code, exception: false)
        return "unknown" if value.nil?
        return "clear" if value <= 1
        return "cloudy" if value <= 3
        return "fog" if value.in?(45..48)
        return "rain" if value.in?(51..67) || value.in?(80..82)
        return "snow" if value.in?(71..77) || value.in?(85..86)
        return "storm" if value >= 95

        "mixed"
      end
    end
  end
end
