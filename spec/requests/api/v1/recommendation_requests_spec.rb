require "rails_helper"

RSpec.describe "API v1 recommendation requests", type: :request do
  let(:user) { create(:user) }

  it "returns the current user's recommendation history with grouped outfits" do
    recommendation = create(:recommendation_request, user: user, prompt: "Wedding reception")
    outfit = create(:outfit, user: user, recommendation_request: recommendation)
    other_user = create(:user)
    create(:recommendation_request, user: other_user)

    get "/api/v1/recommendation_requests", headers: auth_headers(user)

    body = response.parsed_body
    expect(response).to have_http_status(:ok)
    expect(body.dig("data").pluck("id")).to eq([ recommendation.id ])
    expect(body.dig("data", 0, "outfits").pluck("id")).to eq([ outfit.id ])
  end

  it "does not expose another user's recommendation request" do
    recommendation = create(:recommendation_request)

    get "/api/v1/recommendation_requests/#{recommendation.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end
end
