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
      expect(body.dig("data", "timezones")).to include(
        "key" => "Europe/Berlin",
        "label" => "Europe/Berlin"
      )
      expect(body.dig("data", "timezone_countries", "Europe/Berlin")).to eq("DE")
      expect(body.dig("data", "legal")).to include(
        "minimum_age" => 18,
        "ai_processing_required" => true,
        "full_body_image_consent_required" => true
      )
      expect(body.dig("data", "legal", "terms", "version")).to eq(User::TERMS_VERSION)
      expect(body.dig("data", "style_profile", "preferred_styles")).to include(
        "key" => "minimal",
        "label" => "Minimal"
      )
      expect(body.dig("data", "style_profile", "preferred_styles")).to include(
        "key" => "traditional_indian",
        "label" => "Traditional Indian"
      )
      expect(body.dig("data", "style_profile", "fit_preferences", "tops")).to include(
        "key" => "regular",
        "label" => "Regular"
      )
      expect(body.dig("data", "clothing_items", "categories")).to include(
        hash_including("key" => "top", "label" => "Top")
      )
      expect(body.dig("data", "clothing_items", "categories")).to include(
        hash_including("key" => "one_piece", "label" => "One Piece")
      )
      expect(body.dig("data", "clothing_items", "categories")).to include(
        hash_including("key" => "set", "label" => "Set")
      )
      expect(body.dig("data", "clothing_items", "statuses")).to include(
        "key" => "ready",
        "label" => "Ready"
      )
      expect(body.dig("data", "clothing_items", "usage_contexts")).to include(
        "key" => "walking",
        "label" => "Walking"
      )
      expect(body.dig("data", "outfits", "roles")).to include(
        "key" => "shoes",
        "label" => "Shoes"
      )
      expect(body.dig("data", "outfits", "base_compositions")).to include(
        "key" => "set",
        "label" => "Set",
        "roles" => [ "set" ]
      )
      expect(body.dig("data", "outfits", "base_compositions")).to include(
        "key" => "drape",
        "label" => "Drape and Top",
        "roles" => %w[drape top]
      )
      expect(body.dig("data", "outfits", "statuses")).to include(
        "key" => "recommended",
        "label" => "Recommended"
      )
    end

    it "is available before authentication for signup defaults" do
      get "/api/v1/metadata"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "countries")).to be_present
    end
  end
end
