require "rails_helper"

RSpec.describe "API v1 clothing items", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/clothing_items" do
    it "returns only the current user's active clothing items" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", primary_color: "navy")
      create(:clothing_item, user: user, wardrobe: user.wardrobe, discarded_at: Time.current)
      other_user = create(:user)
      create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe)

      get "/api/v1/clothing_items", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data").pluck("id")).to eq([ item.id ])
    end

    it "filters by category, status, and primary color" do
      matching = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "shoes", subcategory: "sneakers", primary_color: "white", status: "ready")
      create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", primary_color: "white", status: "ready")

      get "/api/v1/clothing_items", params: {
        category: "shoes",
        status: "ready",
        primary_color: "white"
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data").pluck("id")).to eq([ matching.id ])
    end
  end

  describe "POST /api/v1/clothing_items" do
    it "creates a processing item with an attached image" do
      post "/api/v1/clothing_items", params: {
        clothing_item: {
          image: uploaded_png,
          name: "White sneakers",
          category: "shoes",
          subcategory: "sneakers",
          primary_color: "white",
          secondary_colors: [ "gray" ],
          season_tags: [ "summer" ],
          occasion_tags: [ "casual" ],
          style_tags: [ "minimal" ],
          formality_score: 3
        }
      }, headers: auth_headers(user)

      item = user.clothing_items.last
      expect(response).to have_http_status(:created)
      expect(item).to be_processing
      expect(item.image).to be_attached
      expect(response.parsed_body.dig("data", "image", "signed_id")).to be_present
    end

    it "rejects invalid taxonomy values" do
      post "/api/v1/clothing_items", params: {
        clothing_item: {
          category: "spacesuit",
          subcategory: "helmet"
        }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("category")
    end
  end

  describe "GET /api/v1/clothing_items/:id" do
    it "returns an owned item" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)

      get "/api/v1/clothing_items/#{item.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(item.id)
    end

    it "does not expose another user's item" do
      other_user = create(:user)
      item = create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe)

      get "/api/v1/clothing_items/#{item.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/clothing_items/:id" do
    it "updates metadata correction fields" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, name: "Old name")

      patch "/api/v1/clothing_items/#{item.id}", params: {
        clothing_item: {
          name: "Navy textured polo",
          category: "top",
          subcategory: "polo",
          primary_color: "navy",
          formality_score: 4
        }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(item.reload.name).to eq("Navy textured polo")
      expect(item.primary_color).to eq("navy")
    end
  end

  describe "DELETE /api/v1/clothing_items/:id" do
    it "soft deletes the item" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)

      delete "/api/v1/clothing_items/#{item.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(item.reload).to be_discarded
    end
  end

  describe "POST /api/v1/clothing_items/:id/reanalyze" do
    it "marks the item as processing" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, status: "ready")

      post "/api/v1/clothing_items/#{item.id}/reanalyze", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(item.reload).to be_processing
    end
  end
end
