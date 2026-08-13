require "rails_helper"

RSpec.describe ExternalContext::WeatherAvailability do
  let(:today) { Time.current.in_time_zone("Europe/Berlin").to_date }

  it "marks returned weather as available" do
    result = ExternalContext::Result.new(city: "Berlin", country_code: "DE", weather: [ { "condition" => "clear" } ])

    expect(described_class.call(result: result, requested_date: today, timezone: "Europe/Berlin")).to include(
      "weather_status" => "available", "weather_status_label" => "Available"
    )
  end

  it "distinguishes missing location, forecast horizon, and provider failure" do
    no_location = ExternalContext::Result.new(city: nil, country_code: "DE", weather: [])
    future = ExternalContext::Result.new(city: "Berlin", country_code: "DE", weather: [])

    expect(described_class.call(result: no_location, requested_date: today, timezone: "Europe/Berlin"))
      .to include("weather_unavailable_reason" => "location_missing")
    expect(described_class.call(result: future, requested_date: today + 30.days, timezone: "Europe/Berlin"))
      .to include("weather_unavailable_reason" => "outside_forecast_range")
    expect(described_class.call(result: future, requested_date: today + 1.day, timezone: "Europe/Berlin"))
      .to include("weather_unavailable_reason" => "provider_unavailable")
  end
end
