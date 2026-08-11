require "rails_helper"

RSpec.describe "API v1 me", type: :request do
  let(:user) { create(:user, first_name: "Alex", preferred_city: "New York") }

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get "/api/v1/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "email")).to eq(user.email)
    end

    it "requires authentication" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates profile fields" do
      patch "/api/v1/me", params: {
        user: {
          first_name: "Avery",
          preferred_city: "Berlin",
          country_code: "de"
        }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "first_name")).to eq("Avery")
      expect(response.parsed_body.dig("data", "country_code")).to eq("DE")
      expect(user.reload.preferred_city).to eq("Berlin")
    end
  end
end
