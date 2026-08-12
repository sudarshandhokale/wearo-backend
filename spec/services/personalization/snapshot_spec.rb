require "rails_helper"

RSpec.describe Personalization::Snapshot do
  it "maps recently worn clothing item IDs to their latest date" do
    user = create(:user)
    outfit = create(:outfit, user: user)
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    create(:outfit_item, outfit: outfit, clothing_item: item)
    create(:wear_history, user: user, outfit: outfit, worn_on: Date.new(2026, 8, 10))

    result = described_class.call(user: user, as_of: Date.new(2026, 8, 12))

    expect(result.dig("last_worn_by_item_id", item.id.to_s)).to eq("2026-08-10")
  end
end
