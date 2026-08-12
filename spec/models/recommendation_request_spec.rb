require "rails_helper"

RSpec.describe RecommendationRequest, type: :model do
  subject(:recommendation_request) { build(:recommendation_request) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:outfits).dependent(:nullify) }

  it "rejects prompts over the storage boundary" do
    recommendation_request.prompt = "a" * 1_001

    expect(recommendation_request).not_to be_valid
    expect(recommendation_request.errors[:prompt]).to be_present
  end
end
