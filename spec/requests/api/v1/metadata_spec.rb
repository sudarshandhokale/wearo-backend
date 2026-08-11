require "rails_helper"

RSpec.describe "API v1 metadata", type: :request do
  describe "GET /api/v1/metadata" do
    it "returns selection metadata for the app" do
      user = create(:user)

      get "/api/v1/metadata", headers: auth_headers(user)

      body = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(body.dig("data", "countries")).to include(
        "code" => "US",
        "name" => "United States of America"
      )
      expect(body.dig("data", "style_profile", "preferred_styles")).to include(
        "key" => "minimal",
        "label" => "Minimal"
      )
      expect(body.dig("data", "style_profile", "fit_preferences", "tops")).to include(
        "key" => "regular",
        "label" => "Regular"
      )
    end

    it "requires authentication" do
      get "/api/v1/metadata"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
