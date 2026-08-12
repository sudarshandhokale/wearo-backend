require "rails_helper"

RSpec.describe AccountTokens do
  let(:user) { create(:user, confirmed_at: nil) }

  it "verifies an email confirmation token for its unchanged account email" do
    expect(described_class.verify_confirmation(described_class.confirmation(user))).to eq(user)
  end

  it "expires confirmation tokens" do
    token = described_class.confirmation(user)

    travel 3.days do
      expect { described_class.verify_confirmation(token) }.to raise_error(AccountTokens::InvalidTokenError)
    end
  end

  it "invalidates a password reset token after the password changes" do
    token = described_class.password_reset(user)
    user.update!(password: "changedpass123", password_confirmation: "changedpass123")

    expect { described_class.verify_password_reset(token) }.to raise_error(AccountTokens::InvalidTokenError)
  end
end
