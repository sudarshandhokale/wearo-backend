require "rails_helper"

RSpec.describe "API v1 auth", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates a consented user and sends email confirmation without a session token" do
      expect do
        post "/api/v1/auth/register", params: {
        user: {
          first_name: "Maya",
          last_name: "Rao",
          email: "maya@example.com",
          password: "password123",
          password_confirmation: "password123",
          timezone: "Asia/Kolkata",
          country_code: "in",
          preferred_city: "Mumbai",
          accept_terms: true,
          accept_privacy: true,
          accept_ai_processing: true,
          confirm_adult: true
        }
        }
      end.to have_enqueued_mail(AccountMailer, :email_confirmation)

      body = response.parsed_body
      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to be_nil
      expect(body.dig("data", "message")).to eq(I18n.t("auth.registration_pending_confirmation"))
      user = User.find_by!(email: "maya@example.com")
      expect(user).not_to be_confirmed
      expect(user).to have_attributes(country_code: "IN", terms_version: User::TERMS_VERSION, privacy_version: User::PRIVACY_VERSION)
      expect(user.ai_processing_consent_at).to be_present
    end

    it "auto-confirms and returns a session when email confirmation is disabled" do
      allow(AppConfig).to receive(:fetch).and_call_original
      allow(AppConfig).to receive(:fetch).with(:email_confirmation_required, default: true).and_return("false")

      expect do
        post "/api/v1/auth/register", params: {
          user: {
            first_name: "Ava",
            email: "ava@example.com",
            password: "password123",
            password_confirmation: "password123",
            accept_terms: true,
            accept_privacy: true,
            accept_ai_processing: true,
            confirm_adult: true
          }
        }
      end.not_to have_enqueued_mail(AccountMailer, :email_confirmation)

      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(User.find_by!(email: "ava@example.com")).to be_confirmed
    end

    it "returns validation errors" do
      post "/api/v1/auth/register", params: {
        user: {
          first_name: "",
          email: "not-an-email",
          password: "short",
          password_confirmation: "different",
          accept_terms: false,
          accept_privacy: false,
          accept_ai_processing: false,
          confirm_adult: false
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include(
        "first_name", "email", "password", "password_confirmation", "accept_terms",
        "accept_privacy", "accept_ai_processing", "confirm_adult"
      )
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

    it "rejects valid credentials until email is confirmed" do
      user.update_column(:confirmed_at, nil)

      post "/api/v1/auth/login", params: {
        user: { email: user.email, password: "password123" }
      }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("auth.email_not_confirmed"))
    end
  end


  describe "email confirmation" do
    let(:user) { create(:user, confirmed_at: nil) }

    it "confirms an account and returns its first session token" do
      post "/api/v1/auth/confirmations/verify", params: { token: AccountTokens.confirmation(user) }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(user.reload).to be_confirmed

      post "/api/v1/auth/confirmations/verify", params: { token: AccountTokens.confirmation(user) }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns a generic response when resending to an unknown email" do
      post "/api/v1/auth/confirmations", params: { user: { email: "missing@example.com" } }

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body.dig("data", "message")).to eq(I18n.t("auth.confirmation_sent"))
    end
  end


  describe "password recovery" do
    let(:user) { create(:user, password: "password123") }

    it "sends a generic recovery response" do
      expect do
        post "/api/v1/auth/password/forgot", params: { user: { email: user.email } }
      end.to have_enqueued_mail(AccountMailer, :password_reset)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body.dig("data", "message")).to eq(I18n.t("auth.password_reset_sent"))
    end

    it "resets a password once with a valid token" do
      token = AccountTokens.password_reset(user)
      previous_session = Auth::Token.encode(user)

      post "/api/v1/auth/password/reset", params: {
        token: token,
        user: { password: "newpassword123", password_confirmation: "newpassword123" }
      }

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("newpassword123")).to be(true)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{previous_session}" }
      expect(response).to have_http_status(:unauthorized)

      post "/api/v1/auth/password/reset", params: {
        token: token,
        user: { password: "anotherpass123", password_confirmation: "anotherpass123" }
      }
      expect(response).to have_http_status(:unprocessable_content)
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
