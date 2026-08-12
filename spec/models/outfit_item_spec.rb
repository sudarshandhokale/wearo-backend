require "rails_helper"

RSpec.describe OutfitItem, type: :model do
  subject(:outfit_item) { build(:outfit_item, outfit: outfit, clothing_item: clothing_item) }

  let(:outfit) { create(:outfit) }
  let(:clothing_item) do
    create(:clothing_item, user: outfit.user, wardrobe: outfit.user.wardrobe, category: "top", subcategory: "polo")
  end

  it { is_expected.to belong_to(:outfit) }
  it { is_expected.to belong_to(:clothing_item) }
  it { is_expected.to validate_inclusion_of(:role).in_array(OutfitTaxonomy.role_keys) }
  it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

  it "requires the outfit and clothing item to have the same owner" do
    outfit = create(:outfit)
    other_user = create(:user)
    clothing_item = create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe)
    item = build(:outfit_item, outfit: outfit, clothing_item: clothing_item)

    expect(item).not_to be_valid
    expect(item.errors[:clothing_item]).to be_present
  end

  it "requires the role to match the clothing category" do
    item = build(:outfit_item, outfit: outfit, clothing_item: clothing_item, role: "shoes")

    expect(item).not_to be_valid
    expect(item.errors[:role]).to be_present
  end

  it "rejects clothing that was already discarded" do
    clothing_item = create(:clothing_item)
    clothing_item.discard!
    item = build(
      :outfit_item,
      outfit: create(:outfit, user: clothing_item.user),
      clothing_item: clothing_item,
      role: clothing_item.category
    )

    expect(item).not_to be_valid
    expect(item.errors[:clothing_item]).to be_present
  end

  it "does not allow duplicate clothing items in one outfit" do
    existing_item = create(:outfit_item)
    duplicate = build(
      :outfit_item,
      outfit: existing_item.outfit,
      clothing_item: existing_item.clothing_item,
      role: existing_item.role,
      position: 1
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:clothing_item_id]).to be_present
  end

  it "does not allow duplicate positions in one outfit" do
    existing_item = create(:outfit_item)
    clothing_item = create(
      :clothing_item,
      user: existing_item.outfit.user,
      wardrobe: existing_item.outfit.user.wardrobe,
      category: "bottom",
      subcategory: "jeans"
    )
    duplicate_position = build(
      :outfit_item,
      outfit: existing_item.outfit,
      clothing_item: clothing_item,
      role: "bottom",
      position: existing_item.position
    )

    expect(duplicate_position).not_to be_valid
    expect(duplicate_position.errors[:position]).to be_present
  end
end
