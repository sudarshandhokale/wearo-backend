require "rails_helper"

RSpec.describe Ai::UsageTracker do
  let(:user) { create(:user) }

  it "reserves capacity and records provider usage" do
    ai_request = described_class.start!(
      user: user,
      operation: "stylist_recommendation",
      trackable: nil,
      reserved_tokens: 3_000
    )

    described_class.succeed!(
      ai_request,
      {
        "provider" => "openai",
        "model" => "test-model",
        "response_id" => "resp_usage_1",
        "attempt_count" => 2,
        "usage" => { "input_tokens" => 120, "output_tokens" => 30, "total_tokens" => 150 }
      }
    )

    expect(ai_request.reload).to be_succeeded
    expect(ai_request).to have_attributes(total_tokens: 150, reserved_tokens: 0, attempt_count: 2)
    expect(described_class.daily_summary(user)).to include(tokens_used: 150, requests_used: 1)
  end

  it "rejects a reservation that would exceed the configured daily token limit" do
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:ai_daily_token_limit, default: 50_000).and_return("100")

    expect do
      described_class.start!(user: user, operation: "clothing_analysis", trackable: nil, reserved_tokens: 101)
    end.to raise_error(Ai::UsageLimitExceededError)
  end

  it "releases reservations and stores a sanitized failure code" do
    ai_request = described_class.start!(
      user: user,
      operation: "clothing_analysis",
      trackable: nil,
      reserved_tokens: 5_000
    )

    described_class.fail!(ai_request, ClothingAnalysis::ProviderError.new("secret provider details"))

    expect(ai_request.reload).to have_attributes(
      status: "failed",
      reserved_tokens: 0,
      failure_code: "provider_error"
    )
  end
end
