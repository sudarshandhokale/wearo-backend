require "rails_helper"

RSpec.describe "API v1 auth", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates a user and returns a token" do
      post "/api/v1/auth/register", params: {
        user: {
          first_name: "Maya",
          last_name: "Rao",
          email: "maya@example.com",
          password: "password123",
          password_confirmation: "password123",
          timezone: "Asia/Kolkata",
          country_code: "in",
          preferred_city: "Mumbai"
        }
      }

      body = response.parsed_body
      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(body.dig("data", "email")).to eq("maya@example.com")
      expect(body.dig("data", "country_code")).to eq("IN")
    end

    it "returns validation errors" do
      post "/api/v1/auth/register", params: {
        user: {
          first_name: "",
          email: "not-an-email",
          password: "short",
          password_confirmation: "different"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("first_name", "email", "password_confirmation")
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "returns a token for valid credentials" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "LOGIN@example.com",
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(user.reload.sign_in_count).to eq(1)
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "login@example.com",
          password: "wrong-password"
        }
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let(:user) { create(:user) }

    it "returns a new token for an authenticated user" do
      post "/api/v1/auth/refresh", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(response.parsed_body.dig("data", "message")).to eq(I18n.t("auth.token_refreshed"))
    end
  end

  describe "POST /api/v1/auth/logout" do
    let(:user) { create(:user) }
    let(:token) { Auth::Token.encode(user) }

    it "revokes the current token" do
      post "/api/v1/auth/logout", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JwtDenylist.count).to eq(1)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
