require "rails_helper"

RSpec.describe Stylist::WardrobeSuggestions do
  it "suggests missing optional items without requiring them" do
    candidates = {
      "shoes" => [],
      "accessory" => [],
      "outerwear" => []
    }

    result = described_class.call(candidates: candidates, context: { "season" => "winter" })

    expect(result.pluck(:key)).to eq(%w[add_shoes add_accessory add_outerwear])
    expect(result).to all(include(:role, :message))
  end

  it "does not suggest optional roles already present or irrelevant outerwear" do
    candidates = {
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "accessory" => [ build_stubbed(:clothing_item, category: "accessory") ],
      "outerwear" => []
    }

    expect(described_class.call(candidates: candidates, context: {})).to be_empty
  end
end
