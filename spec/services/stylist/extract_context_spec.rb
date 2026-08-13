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

  it "extracts ISO, written, and unambiguous numeric dates with optional times" do
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 13, 10, 0)

    iso = described_class.call("Dinner on 2026-08-20 at 7:30pm", timezone: "Europe/Berlin", now: now)
    written = described_class.call("Concert Aug 21", timezone: "Europe/Berlin", now: now)
    numeric = described_class.call("Wedding on 22/08/2026", timezone: "Europe/Berlin", now: now)

    expect(iso.recommended_for.strftime("%F %H:%M %z")).to eq("2026-08-20 19:30 +0200")
    expect(written.recommended_for.to_date).to eq(Date.new(2026, 8, 21))
    expect(numeric.recommended_for.to_date).to eq(Date.new(2026, 8, 22))
  end


  it "extracts ordinal dates that include of" do
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 13, 10, 0)

    result = described_class.call("Wedding on the 20th of August", timezone: "Europe/Berlin", now: now)

    expect(result.recommended_for.to_date).to eq(Date.new(2026, 8, 20))
  end

  it "moves a yearless written date to the next occurrence" do
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 13, 10, 0)

    result = described_class.call("Dinner on August 12", timezone: "Europe/Berlin", now: now)

    expect(result.recommended_for.to_date).to eq(Date.new(2027, 8, 12))
  end

  it "treats next weekday as the following week when today has that weekday" do
    friday = Time.find_zone!("Europe/Berlin").local(2026, 8, 14, 10, 0)

    result = described_class.call("Dinner next Friday", timezone: "Europe/Berlin", now: friday)

    expect(result.recommended_for.to_date).to eq(Date.new(2026, 8, 21))
  end

  it "rejects past, invalid, and ambiguous explicit dates" do
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 13, 10, 0)

    expect { described_class.call("Dinner on 2026-08-12", timezone: "Europe/Berlin", now: now) }
      .to raise_error(Stylist::InvalidPromptError)
    expect { described_class.call("Dinner on 31/02/2027", timezone: "Europe/Berlin", now: now) }
      .to raise_error(Stylist::InvalidPromptError)
    expect { described_class.call("Dinner on 03/04/2027", timezone: "Europe/Berlin", now: now) }
      .to raise_error(Stylist::InvalidPromptError)
  end
end
