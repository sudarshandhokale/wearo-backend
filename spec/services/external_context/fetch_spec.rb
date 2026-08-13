require "rails_helper"

RSpec.describe ExternalContext::Fetch do
  it "uses the preferred city and fetches weather" do
    user = create(:user, preferred_city: "Berlin", country_code: "DE")
    requested_date = Time.current.in_time_zone(user.timezone).to_date
    weather = instance_double(ExternalContext::Weather::OpenMeteo)
    allow(weather).to receive(:call).and_return([ { "date" => requested_date.iso8601 } ])

    result = described_class.call(
      user: user,
      start_date: requested_date,
      end_date: requested_date,
      weather_provider: weather
    )

    expect(result.city).to eq("Berlin")
    expect(result.weather).to contain_exactly("date" => requested_date.iso8601)
  end


  it "does not call the provider outside the live forecast window" do
    user = create(:user, preferred_city: "Berlin", country_code: "DE")
    weather = instance_double(ExternalContext::Weather::OpenMeteo)
    allow(weather).to receive(:call)
    requested_date = Time.current.in_time_zone(user.timezone).to_date + 30.days

    result = described_class.call(
      user: user, start_date: requested_date, end_date: requested_date, weather_provider: weather
    )

    expect(result.weather).to be_empty
    expect(weather).not_to have_received(:call)
  end

  it "rejects ranges beyond the provider forecast horizon" do
    expect do
      described_class.call(user: create(:user), start_date: "2026-08-01", end_date: "2026-08-20")
    end.to raise_error(ExternalContext::InvalidDateRangeError)
  end

  it "prefers an explicit destination over the profile city" do
    user = create(:user, preferred_city: "Hamburg", country_code: "DE")
    weather = instance_double(ExternalContext::Weather::OpenMeteo)
    allow(weather).to receive(:call).and_return([])

    result = described_class.call(user: user, city: "Paris", weather_provider: weather)

    expect(result.city).to eq("Paris")
    expect(weather).to have_received(:call).with(
      city: "Paris",
      country_code: "DE",
      start_date: Date.current,
      end_date: Date.current
    )
  end
end
