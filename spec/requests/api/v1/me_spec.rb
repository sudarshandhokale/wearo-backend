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


    it "uploads and returns a private full-body profile image" do
      patch "/api/v1/me", params: {
        user: { full_body_image: uploaded_png("full-body.png") }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.full_body_image).to be_attached
      expect(response.parsed_body.dig("data", "full_body_image")).to include("signed_id", "url")
    end

    it "rejects an unsupported full-body profile image" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("not-an-image"),
        "text/plain",
        original_filename: "profile.txt"
      )

      patch "/api/v1/me", params: { user: { full_body_image: file } }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("profile.update_failed"))
    end
  end

  describe "DELETE /api/v1/me/full_body_image" do
    it "deletes the saved full-body profile image" do
      user.full_body_image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "profile.png", content_type: "image/png")

      delete "/api/v1/me/full_body_image", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.full_body_image).not_to be_attached
      expect(response.parsed_body.dig("data", "message")).to eq(I18n.t("profile.full_body_image_deleted"))
    end
  end
end
