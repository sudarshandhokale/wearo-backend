require "rails_helper"

RSpec.describe Stylist::CandidateSelector do
  let(:user) { create(:user) }
  let(:context) { { "occasion" => "casual", "formality" => "casual" } }

  it "selects only the current user's active ready clothing" do
    top = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")
    bottom = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "jeans", status: "ready")
    shoes = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "shoes", subcategory: "sneakers", status: "ready")
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "shirt", status: "processing")
    discarded = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "shirt", status: "ready")
    discarded.discard!
    other_user = create(:user)
    create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe, category: "top", subcategory: "shirt", status: "ready")

    result = described_class.call(user: user, context: context)

    expect(result["top"]).to eq([ top ])
    expect(result["bottom"]).to eq([ bottom ])
    expect(result["shoes"]).to eq([ shoes ])
  end

  it "reports required wardrobe roles that are missing" do
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")

    expect { described_class.call(user: user, context: context) }
      .to raise_error(Stylist::InsufficientWardrobeError) { |error| expect(error.missing_roles).to contain_exactly("bottom", "shoes") }
  end
end
