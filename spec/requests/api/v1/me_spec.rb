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
        user: { full_body_image: uploaded_png("full-body.png"), full_body_image_consent: true }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.full_body_image).to be_attached
      expect(response.parsed_body.dig("data", "full_body_image")).to include("signed_id", "url")
    end


    it "requires explicit consent for a full-body profile image" do
      patch "/api/v1/me", params: {
        user: { full_body_image: uploaded_png("full-body.png") }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("consent.full_body_image_required"))
      expect(user.reload.full_body_image).not_to be_attached
    end

    it "rejects an unsupported full-body profile image" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("not-an-image"),
        "text/plain",
        original_filename: "profile.txt"
      )

      patch "/api/v1/me", params: {
        user: { full_body_image: file, full_body_image_consent: true }
      }, headers: auth_headers(user)

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

  describe "PATCH /api/v1/me/consents" do
    it "records current policy and AI consent versions for an existing account" do
      user.update_columns(
        terms_accepted_at: nil,
        terms_version: nil,
        privacy_accepted_at: nil,
        privacy_version: nil,
        ai_processing_consent_at: nil
      )

      patch "/api/v1/me/consents", params: {
        consents: {
          accept_terms: true,
          accept_privacy: true,
          accept_ai_processing: true,
          confirm_adult: true
        }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload).to have_attributes(
        terms_version: User::TERMS_VERSION,
        privacy_version: User::PRIVACY_VERSION
      )
      expect(user.ai_processing_consent_at).to be_present
    end
  end

  describe "GET /api/v1/me/export" do
    it "downloads a portable copy of user-owned data" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      outfit = create(:outfit, user: user)
      create(:outfit_item, outfit: outfit, clothing_item: item)
      create(:wear_history, user: user, outfit: outfit)

      get "/api/v1/me/export", headers: auth_headers(user)

      export = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(export.dig("profile", "id")).to eq(user.id)
      expect(export.fetch("clothing_items").pluck("id")).to eq([ item.id ])
      expect(export.fetch("outfits").pluck("id")).to eq([ outfit.id ])
      expect(export.fetch("wear_history").length).to eq(1)
    end
  end

  describe "DELETE /api/v1/me" do
    it "deletes the account and all owned images and records" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
      outfit = create(:outfit, user: user)
      create(:outfit_item, outfit: outfit, clothing_item: item)
      create(:wear_history, user: user, outfit: outfit)
      blob_id = item.image.blob.id

      expect do
        delete "/api/v1/me", params: {
          account: { password: "password123", confirmation: "DELETE" }
        }, headers: auth_headers(user)
      end.to have_enqueued_job(ActiveStorage::PurgeJob).at_least(:once)

      expect(response).to have_http_status(:ok)
      expect(User.where(id: user.id)).not_to exist
      expect(ClothingItem.where(id: item.id)).not_to exist
      expect(ActiveStorage::Blob.where(id: blob_id)).to exist
    end

    it "requires the current password and confirmation phrase" do
      delete "/api/v1/me", params: {
        account: { password: "wrong-password", confirmation: "DELETE" }
      }, headers: auth_headers(user)
      expect(response).to have_http_status(:unauthorized)

      delete "/api/v1/me", params: {
        account: { password: "password123", confirmation: "delete" }
      }, headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(User.where(id: user.id)).to exist
    end
  end
end
