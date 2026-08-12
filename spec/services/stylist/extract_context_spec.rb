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
    expect(result.recommended_for.wday).to eq(6)
  end
end
