require "rails_helper"

RSpec.describe Stylist::CombinationBuilder do
  it "builds complete core outfits and adds relevant optional items" do
    candidates = {
      "top" => [ build_stubbed(:clothing_item, category: "top") ],
      "bottom" => [ build_stubbed(:clothing_item, category: "bottom") ],
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "outerwear" => [ build_stubbed(:clothing_item, category: "outerwear") ],
      "accessory" => [ build_stubbed(:clothing_item, category: "accessory") ]
    }

    result = described_class.call(candidates: candidates, context: { "season" => "winter" })

    expect(result.one?).to be(true)
    expect(result.first.items.keys).to eq(%w[top bottom shoes outerwear accessory])
  end
end
