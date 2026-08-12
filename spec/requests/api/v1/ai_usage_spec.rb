require "rails_helper"

RSpec.describe "API v1 AI usage", type: :request do
  let(:user) { create(:user) }

  it "returns only the authenticated user's daily usage and limits" do
    create(:ai_request, user: user, total_tokens: 175)
    create(:ai_request, total_tokens: 900)

    get "/api/v1/ai/usage", headers: auth_headers(user)

    data = response.parsed_body.dig("data")
    expect(response).to have_http_status(:ok)
    expect(data).to include("tokens_used" => 175, "requests_used" => 1)
    expect(data.fetch("token_limit")).to be_positive
  end

  it "requires authentication" do
    get "/api/v1/ai/usage"

    expect(response).to have_http_status(:unauthorized)
  end
end
