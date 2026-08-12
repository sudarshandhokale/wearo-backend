require "rails_helper"

RSpec.describe ClothingItem, type: :model do
  subject(:clothing_item) { build(:clothing_item) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:wardrobe) }
  it { is_expected.to validate_inclusion_of(:category).in_array(ClothingTaxonomy.category_keys).allow_blank }
  it { is_expected.to validate_numericality_of(:formality_score).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(10).allow_nil }

  it "rejects a wardrobe owned by another user" do
    other_user = create(:user)
    item = build(:clothing_item, wardrobe: other_user.wardrobe)

    expect(item).not_to be_valid
    expect(item.errors[:wardrobe]).to be_present
  end

  it "can be discarded without being destroyed" do
    item = create(:clothing_item)

    expect { item.discard! }.to change { item.reload.discarded? }.from(false).to(true)
  end
end
