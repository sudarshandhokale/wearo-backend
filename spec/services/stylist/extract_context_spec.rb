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
      "activity" => "social",
      "usage" => "social"
    )
    expect(result.recommended_for.hour).to eq(19)
    expect(result.city).to be_nil
  end

  it "distinguishes walking, travel, and special-occasion usage" do
    walking = described_class.call("Comfortable clothes for walking", timezone: "UTC")
    travel = described_class.call("Packing for a vacation", timezone: "UTC")
    special = described_class.call("Black tie wedding", timezone: "UTC")

    expect(walking.attributes["usage"]).to eq("walking")
    expect(travel.attributes["usage"]).to eq("travel")
    expect(special.attributes["usage"]).to eq("special_occasion")
  end

  it "rejects an empty prompt" do
    expect { described_class.call(" ", timezone: "UTC") }.to raise_error(Stylist::InvalidPromptError)
  end


  it "extracts Indian wedding and festival occasions" do
    wedding = described_class.call("Sangeet outfit for Saturday", timezone: "Asia/Kolkata")
    festival = described_class.call("What should I wear for Diwali?", timezone: "Asia/Kolkata")

    expect(wedding.attributes).to include("occasion" => "wedding", "formality" => "formal")
    expect(festival.attributes).to include("occasion" => "festival")
  end


  it "extracts a user-provided concert without external event discovery" do
    result = described_class.call(
      "Coldplay concert in Berlin on Saturday",
      timezone: "Europe/Berlin"
    )

    expect(result.attributes).to include(
      "occasion" => "concert",
      "activity" => "music_event",
      "formality" => "casual"
    )
    expect(result.city).to eq("Berlin")
    expect(result.recommended_for.wday).to eq(6)
  end

  it "extracts multi-word destinations without treating seasons as cities" do
    travel = described_class.call("I am traveling to New York next Friday", timezone: "Europe/Berlin")
    seasonal = described_class.call("Something comfortable in summer", timezone: "Europe/Berlin")

    expect(travel.city).to eq("New York")
    expect(seasonal.city).to be_nil
  end
end
