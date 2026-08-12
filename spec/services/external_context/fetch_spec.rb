require "rails_helper"

RSpec.describe ExternalContext::Fetch do
  it "uses the preferred city and fetches weather" do
    user = create(:user, preferred_city: "Berlin", country_code: "DE")
    weather = instance_double(ExternalContext::Weather::OpenMeteo)
    allow(weather).to receive(:call).and_return([ { "date" => "2026-08-12" } ])

    result = described_class.call(
      user: user,
      start_date: "2026-08-12",
      end_date: "2026-08-12",
      weather_provider: weather
    )

    expect(result.city).to eq("Berlin")
    expect(result.weather).to contain_exactly("date" => "2026-08-12")
  end

  it "rejects ranges beyond the provider forecast horizon" do
    expect do
      described_class.call(user: create(:user), start_date: "2026-08-01", end_date: "2026-08-20")
    end.to raise_error(ExternalContext::InvalidDateRangeError)
  end
end
