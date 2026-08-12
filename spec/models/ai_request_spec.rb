require "rails_helper"

RSpec.describe AiRequest, type: :model do
  subject(:ai_request) { build(:ai_request) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_inclusion_of(:operation).in_array(AiRequest::OPERATIONS) }

  it "rejects negative token counts" do
    ai_request.total_tokens = -1

    expect(ai_request).not_to be_valid
  end
end
