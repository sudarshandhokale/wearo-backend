require "rails_helper"

RSpec.describe Stylist::CombinationBuilder do
  it "builds complete core outfits and adds relevant optional items" do
    candidates = {
      "top" => [ build_stubbed(:clothing_item, category: "top") ],
      "bottom" => [ build_stubbed(:clothing_item, category: "bottom") ],
      "one_piece" => [],
      "drape" => [],
      "set" => [],
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "outerwear" => [ build_stubbed(:clothing_item, category: "outerwear") ],
      "accessory" => [ build_stubbed(:clothing_item, category: "accessory") ]
    }

    result = described_class.call(candidates: candidates, context: { "season" => "winter" })

    expect(result.one?).to be(true)
    expect(result.first.items.keys).to eq(%w[top bottom shoes outerwear accessory])
  end


  it "builds a one-piece outfit when separates and shoes are unavailable" do
    dress = build_stubbed(:clothing_item, category: "one_piece", subcategory: "dress")
    candidates = {
      "top" => [],
      "bottom" => [],
      "one_piece" => [ dress ],
      "drape" => [],
      "set" => [],
      "shoes" => [],
      "outerwear" => [],
      "accessory" => []
    }

    result = described_class.call(candidates: candidates, context: {})

    expect(result.one?).to be(true)
    expect(result.first.items).to eq("one_piece" => dress)
  end


  it "builds an outfit from a complete set without separates" do
    matching_set = build_stubbed(:clothing_item, category: "set", subcategory: "co_ord")
    candidates = {
      "top" => [],
      "bottom" => [],
      "one_piece" => [],
      "drape" => [],
      "set" => [ matching_set ],
      "shoes" => [],
      "outerwear" => [],
      "accessory" => []
    }

    result = described_class.call(candidates: candidates, context: {})

    expect(result.one?).to be(true)
    expect(result.first.items).to eq("set" => matching_set)
  end


  it "builds a saree outfit from a drape and blouse" do
    saree = build_stubbed(:clothing_item, category: "drape", subcategory: "saree")
    blouse = build_stubbed(:clothing_item, category: "top", subcategory: "ethnic_blouse")
    candidates = {
      "top" => [ blouse ],
      "bottom" => [],
      "one_piece" => [],
      "drape" => [ saree ],
      "set" => [],
      "shoes" => [],
      "outerwear" => [],
      "accessory" => []
    }

    result = described_class.call(candidates: candidates, context: {})

    expect(result.one?).to be(true)
    expect(result.first.items).to eq("drape" => saree, "top" => blouse)
  end
end
