require "rails_helper"

RSpec.describe Routines::DetectIntent do
  it "detects explicit recurring language" do
    expect(described_class.recurring?("I go to the office every weekday at 8:30")).to be(true)
  end

  it "detects a multi-day schedule with a time" do
    expect(described_class.recurring?("Gym Tuesday Thursday at 6pm")).to be(true)
  end

  it "leaves a one-time weekday request with the stylist" do
    expect(described_class.recurring?("What should I wear to the office Monday at 8:30?")).to be(false)
  end
end
