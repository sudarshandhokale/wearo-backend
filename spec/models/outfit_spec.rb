require "rails_helper"

RSpec.describe Outfit, type: :model do
  subject(:outfit) { build(:outfit) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:outfit_items).dependent(:destroy) }
  it { is_expected.to have_many(:clothing_items).through(:outfit_items) }
  it { is_expected.to validate_numericality_of(:recommendation_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100).allow_nil }

  it "accepts empty structured contexts" do
    outfit.context = {}
    outfit.weather_context = {}

    expect(outfit).to be_valid
  end

  it "rejects invalid structured contexts" do
    outfit.context = []
    outfit.weather_context = []

    expect(outfit).not_to be_valid
    expect(outfit.errors).to include(:context, :weather_context)
  end
end
