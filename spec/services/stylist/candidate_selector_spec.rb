require "rails_helper"

RSpec.describe Stylist::CandidateSelector do
  let(:user) { create(:user) }
  let(:context) { { "occasion" => "casual", "formality" => "casual" } }

  it "selects only the current user's active ready clothing" do
    top = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")
    bottom = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "jeans", status: "ready")
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "shirt", status: "processing")
    discarded = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "shirt", status: "ready")
    discarded.discard!
    other_user = create(:user)
    create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe, category: "top", subcategory: "shirt", status: "ready")

    result = described_class.call(user: user, context: context)

    expect(result["top"]).to eq([ top ])
    expect(result["bottom"]).to eq([ bottom ])
    expect(result["shoes"]).to be_empty
  end

  it "accepts a one-piece wardrobe without tops, bottoms, or shoes" do
    dress = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "one_piece", subcategory: "dress", status: "ready")

    result = described_class.call(user: user, context: context)

    expect(result["one_piece"]).to eq([ dress ])
    expect(result.values_at("top", "bottom", "shoes")).to all(be_empty)
  end

  it "reports missing base roles and accepted combinations" do
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")

    expect { described_class.call(user: user, context: context) }
      .to raise_error(Stylist::InsufficientWardrobeError) do |error|
        expect(error.missing_roles).to contain_exactly("bottom", "one_piece", "drape", "set")
        expect(error.required_combinations).to eq([ %w[top bottom], %w[one_piece], %w[drape top], %w[set] ])
      end
  end

  it "excludes items that the user restricted to a different usage context" do
    top = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", user_usage_tags: [ "travel" ])
    travel_pants = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "trousers", user_usage_tags: [ "travel" ])
    everyday_pants = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "jeans", user_usage_tags: [ "everyday" ])

    result = described_class.call(user: user, context: context.merge("usage" => "travel"))

    expect(result["top"]).to eq([ top ])
    expect(result["bottom"]).to eq([ travel_pants ])
    expect(result["bottom"]).not_to include(everyday_pants)
  end
end
