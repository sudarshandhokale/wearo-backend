require "rails_helper"

RSpec.describe Stylist::ExtractContext do
  it "extracts occasion, formality, activity, and requested time" do
    now = Time.zone.parse("2026-08-12 10:00:00")

    result = described_class.call(
      "Casual dinner with friends tonight",
      timezone: "Europe/Berlin",
      now: now
    )

    expect(result.attributes).to include(
      "occasion" => "dinner",
      "formality" => "smart_casual",
      "activity" => "social"
    )
    expect(result.recommended_for.hour).to eq(19)
  end

  it "rejects an empty prompt" do
    expect { described_class.call(" ", timezone: "UTC") }.to raise_error(Stylist::InvalidPromptError)
  end
end
