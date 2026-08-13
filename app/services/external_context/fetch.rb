module ExternalContext
  class Fetch
    MAX_DAYS = 16

    class << self
      def call(user:, city: nil, start_date: nil, end_date: nil, weather_provider: Weather::OpenMeteo.new)
        location = city.to_s.strip.presence || user.preferred_city
        start_on = parse_date(start_date) || Time.current.in_time_zone(user.timezone).to_date
        end_on = parse_date(end_date) || start_on
        validate_range!(start_on, end_on)
        return Result.new(city: nil, country_code: user.country_code, weather: []) if location.blank?
        return Result.new(city: location, country_code: user.country_code, weather: []) unless forecastable?(start_on, end_on, user.timezone)

        Result.new(
          city: location,
          country_code: user.country_code,
          weather: weather_provider.call(city: location, country_code: user.country_code, start_date: start_on, end_date: end_on)
        )
      end

      private

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue Date::Error
        raise InvalidDateRangeError
      end

      def validate_range!(start_on, end_on)
        days = (end_on - start_on).to_i + 1
        raise InvalidDateRangeError unless days.between?(1, MAX_DAYS)
      end

      def forecastable?(start_on, end_on, timezone)
        local_today = Time.current.in_time_zone(timezone).to_date
        start_on >= local_today && end_on <= local_today + Weather::OpenMeteo::MAX_DAYS - 1
      end
    end
  end
end
