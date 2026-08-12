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
        "name" => "Navy Polo Dinner Edit",
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
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("errors.messages.not_found"))
    end

    it "uses try-on, flat-lay, polished item, and original item cover fallbacks in order" do
      outfit = create(:outfit, user: user)
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "original.png", content_type: "image/png")
      item.polished_image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "polished.png", content_type: "image/png")
      create(:outfit_item, outfit: outfit, clothing_item: item, role: "top", position: 0)

      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)
      expect(response.parsed_body.dig("data", "cover_image")).to include(
        "kind" => "polished_item",
        "clothing_item_id" => item.id
      )

      item.polished_image.purge
      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)
      expect(response.parsed_body.dig("data", "cover_image")).to include(
        "kind" => "original_item",
        "clothing_item_id" => item.id
      )

      flat_lay = create(:outfit_visualization, user: user, outfit: outfit, mode: "flat_lay", status: "ready")
      flat_lay.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "flat-lay.png", content_type: "image/png")
      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)
      expect(response.parsed_body.dig("data", "cover_image")).to include(
        "kind" => "outfit_flat_lay",
        "visualization_id" => flat_lay.id
      )

      try_on = create(:outfit_visualization, user: user, outfit: outfit, mode: "flat_lay", status: "ready")
      try_on.reference_image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "person.png", content_type: "image/png")
      try_on.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "try-on.png", content_type: "image/png")
      try_on.update!(mode: "try_on")
      get "/api/v1/outfits/#{outfit.id}", headers: auth_headers(user)
      expect(response.parsed_body.dig("data", "cover_image")).to include(
        "kind" => "outfit_try_on",
        "personalized" => true,
        "visualization_id" => try_on.id
      )
    end

    it "requires authentication" do
      outfit = create(:outfit, user: user)

      get "/api/v1/outfits/#{outfit.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/outfits/:id" do
    it "stores user feedback and status changes" do
      outfit = create(:outfit, user: user)

      patch "/api/v1/outfits/#{outfit.id}", params: {
        outfit: { status: "worn", rating: 5, feedback_note: "Worked well for dinner" }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(outfit.reload).to have_attributes(status: "worn", rating: 5, feedback_note: "Worked well for dinner")
      expect(outfit.status_updated_at).to be_present
    end

    it "rejects invalid feedback values with a localized message" do
      outfit = create(:outfit, user: user)

      patch "/api/v1/outfits/#{outfit.id}", params: {
        outfit: { status: "unknown", rating: 9 }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("outfits.update_failed"))
    end

    it "does not update another user's outfit" do
      outfit = create(:outfit)

      patch "/api/v1/outfits/#{outfit.id}", params: { outfit: { status: "worn" } }, headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end
end
