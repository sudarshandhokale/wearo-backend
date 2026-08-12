require "rails_helper"

RSpec.describe "API v1 outfits", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/outfits/:id" do
    it "returns an owned outfit with ordered clothing item details" do
      outfit = create(:outfit, user: user, recommendation_score: 92)
      shoes = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "shoes", subcategory: "sneakers")
      top = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo")
      create(:outfit_item, outfit: outfit, clothing_item: shoes, role: "shoes", position: 2)
      create(:outfit_item, outfit: outfit, clothing_item: top, role: "top", position: 0)

      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)

      body = response.parsed_body.dig("data")
      expect(response).to have_http_status(:ok)
      expect(body).to include(
        "id" => outfit.id,
        "recommendation_score" => 92.0,
        "status" => "recommended"
      )
      expect(body.fetch("items").pluck("role")).to eq(%w[top shoes])
      expect(body.dig("items", 0, "clothing_item")).to include(
        "id" => top.id,
        "subcategory" => "polo"
      )
    end

    it "does not expose another user's outfit" do
      other_user = create(:user)
      outfit = create(:outfit, user: other_user)

      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      outfit = create(:outfit, user: user)

      get "/api/v1/outfits/#{outfit.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
