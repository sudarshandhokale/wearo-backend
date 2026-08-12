require "rails_helper"

RSpec.describe "API v1 personalization", type: :request do
  let(:user) { create(:user) }
  let(:outfit) { create(:outfit, user: user) }

  describe "POST /api/v1/outfits/:id/wear" do
    it "records a wear once per date and updates the outfit" do
      2.times do
        post "/api/v1/outfits/#{outfit.id}/wear", params: {
          wear: { worn_on: "2026-08-12", occasion: "work" }
        }, headers: auth_headers(user)
      end

      expect(response).to have_http_status(:created)
      expect(user.wear_histories.count).to eq(1)
      expect(user.wear_histories.first).to have_attributes(worn_on: Date.new(2026, 8, 12), occasion: "work")
      expect(outfit.reload).to be_worn
    end

    it "rejects an invalid date with a localized message" do
      post "/api/v1/outfits/#{outfit.id}/wear", params: { wear: { worn_on: "not-a-date" } }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("outfits.wear_failed"))
    end
  end

  describe "POST /api/v1/outfits/:id/feedback" do
    it "upserts feedback and learns without replacing explicit preferences" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, primary_color: "green", style_tags: [ "relaxed" ])
      create(:outfit_item, outfit: outfit, clothing_item: item, role: "top")

      post "/api/v1/outfits/#{outfit.id}/feedback", params: {
        feedback: { reaction: "liked", notes: "Good fit" }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(outfit.reload).to be_saved
      learned = user.style_profile.reload.additional_preferences.fetch("learned")
      expect(learned.fetch("preferred_colors")).to include("green")
      expect(user.style_profile.preferred_colors).to eq([])
    end

    it "does not expose another user's outfit" do
      post "/api/v1/outfits/#{create(:outfit).id}/feedback", params: {
        feedback: { reaction: "disliked", reason: "not_my_style" }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/wear_history" do
    it "returns only the current user's history" do
      create(:wear_history, user: user, outfit: outfit)
      create(:wear_history)

      get "/api/v1/wear_history", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("outfit_id")).to eq([ outfit.id ])
    end
  end
end
