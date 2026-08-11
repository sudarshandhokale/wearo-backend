require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to validate_presence_of(:first_name) }

  it "creates a default style profile and wardrobe" do
    user = create(:user)

    expect(user.style_profile).to be_present
    expect(user.wardrobe).to be_present
    expect(user.wardrobe.name).to eq(Wardrobe::DEFAULT_NAME)
  end

  it "normalizes email and country code" do
    user.email = " ALEX@EXAMPLE.COM "
    user.country_code = "in"
    user.validate

    expect(user.email).to eq("alex@example.com")
    expect(user.country_code).to eq("IN")
  end

  it "defaults blank timezone and country code" do
    user.timezone = ""
    user.country_code = ""
    user.validate

    expect(user.timezone).to eq("UTC")
    expect(user.country_code).to eq("US")
  end
end
