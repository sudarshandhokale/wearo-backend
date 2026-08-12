require "rails_helper"

RSpec.describe Stylist::WardrobeSuggestions do
  it "suggests missing optional items without requiring them" do
    candidates = {
      "shoes" => [],
      "accessory" => [],
      "outerwear" => []
    }

    result = described_class.call(candidates: candidates, context: { "season" => "winter" })

    expect(result.pluck(:key)).to contain_exactly("add_shoes", "add_accessory", "add_outerwear")
    expect(result).to all(include(:role, :type, :priority, :action, :message, :question))
  end

  it "does not suggest optional roles already present or irrelevant outerwear" do
    candidates = {
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "accessory" => [ build_stubbed(:clothing_item, category: "accessory") ],
      "outerwear" => []
    }

    expect(described_class.call(candidates: candidates, context: {})).to be_empty
  end


  it "suggests bringing rain protection when no suitable owned item exists" do
    candidates = {
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "accessory" => [],
      "outerwear" => []
    }

    result = described_class.call(
      candidates: candidates,
      context: { "weather" => { "condition" => "rain", "precipitation_probability" => 80 } }
    )

    expect(result.first).to include(
      key: "bring_rain_protection",
      type: "weather",
      priority: "essential",
      action: "bring",
      suggested_subcategories: %w[umbrella raincoat water_resistant_shoes]
    )
  end


  it "references an owned umbrella instead of suggesting another purchase" do
    umbrella = build_stubbed(:clothing_item, category: "accessory", subcategory: "umbrella", name: "Black umbrella")
    candidates = { "shoes" => [], "accessory" => [ umbrella ], "outerwear" => [] }

    result = described_class.call(
      candidates: candidates,
      context: { "weather" => { "condition" => "rain" } }
    )

    expect(result.first).to include(
      key: "use_owned_rain",
      action: "use_owned_item",
      clothing_item_id: umbrella.id
    )
  end


  it "suggests an owned occasion-appropriate accessory not already selected" do
    bag = build_stubbed(:clothing_item, category: "accessory", subcategory: "bag", name: "Evening bag")
    jewelry = build_stubbed(:clothing_item, category: "accessory", subcategory: "jewelry", name: "Silver necklace")
    candidates = { "shoes" => [], "accessory" => [ bag, jewelry ], "outerwear" => [] }

    result = described_class.call(
      candidates: candidates,
      context: { "occasion" => "dinner" },
      selected_item_ids: [ bag.id ]
    )

    expect(result).to include(hash_including(
      key: "use_owned_finishing_touch",
      action: "use_owned_item",
      clothing_item_id: jewelry.id
    ))
  end


  it "advises adding versatile items when the ready core wardrobe is limited" do
    user = build_stubbed(:user)
    candidates = {
      "top" => [ build_stubbed(:clothing_item, category: "top") ],
      "bottom" => [ build_stubbed(:clothing_item, category: "bottom") ],
      "one_piece" => [],
      "drape" => [],
      "set" => [],
      "shoes" => [ build_stubbed(:clothing_item, category: "shoes") ],
      "accessory" => [ build_stubbed(:clothing_item, category: "accessory") ],
      "outerwear" => []
    }

    result = described_class.call(candidates: candidates, context: {}, user: user)

    expect(result).to include(hash_including(
      key: "expand_core_wardrobe",
      type: "wardrobe",
      priority: "recommended",
      action: "add_to_wardrobe",
      suggested_subcategories: %w[t_shirt shirt blouse kurta]
    ))
  end
end
