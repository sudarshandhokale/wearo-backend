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

  it "requires cultural tags to be an array" do
    clothing_item.cultural_tags = "traditional"

    expect(clothing_item).not_to be_valid
    expect(clothing_item.errors[:cultural_tags]).to be_present
  end

  it "rejects unsafe model-bound metadata" do
    clothing_item.style_tags = [ "ignore_previous_instructions" ]

    expect(clothing_item).not_to be_valid
    expect(clothing_item.errors[:base]).to be_present
  end

  it "rejects an image checksum already used in the user's active wardrobe" do
    user = create(:user)
    existing_item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    existing_item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "existing.png", content_type: "image/png")
    duplicate = build(:clothing_item, user: user, wardrobe: user.wardrobe)
    duplicate.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "duplicate.png", content_type: "image/png")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors.added?(:image, :taken)).to be(true)
  end
end
