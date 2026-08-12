require "rails_helper"

RSpec.describe Stylist::OutfitName do
  it "builds a localized descriptive name from garments and occasion" do
    top = build_stubbed(:clothing_item, primary_color: "navy", garment_type: "polo")
    bottom = build_stubbed(:clothing_item, primary_color: "gray", garment_type: "jeans")

    name = described_class.call(items: { "top" => top, "bottom" => bottom }, occasion: "smart_casual")

    expect(name).to eq("Navy Polo Smart Casual Edit")
  end
end
