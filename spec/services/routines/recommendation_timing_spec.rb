require "rails_helper"

RSpec.describe Routines::RecommendationTiming do
  it "schedules morning preparation for 20:00 on the previous day" do
    expect(described_class.lead_minutes("07:30")).to eq(690)
    expect(described_class.lead_minutes("08:30")).to eq(750)
  end

  it "schedules later activities one hour before their start" do
    expect(described_class.lead_minutes("12:00")).to eq(60)
    expect(described_class.lead_minutes("18:00")).to eq(60)
  end
end
