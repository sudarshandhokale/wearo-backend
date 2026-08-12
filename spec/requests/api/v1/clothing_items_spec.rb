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
      expect do
        post "/api/v1/clothing_items", params: {
          clothing_item: {
            image: uploaded_png,
            name: "White jutti",
            garment_type: "Jutti",
            category: "shoes",
            subcategory: "jutti",
            primary_color: "white",
            secondary_colors: [ "gray" ],
            season_tags: [ "summer" ],
            occasion_tags: [ "casual" ],
            style_tags: [ "minimal" ],
            cultural_tags: [ "indian_traditional" ],
            formality_score: 3
          }
        }, headers: auth_headers(user)
      end.to have_enqueued_job(AnalyzeClothingItemJob).exactly(:once)

      item = user.clothing_items.last
      expect(response).to have_http_status(:created)
      expect(item).to be_processing
      expect(item.image).to be_attached
      expect(item.garment_type).to eq("Jutti")
      expect(item.cultural_tags).to eq([ "indian_traditional" ])
      expect(response.parsed_body.dig("data", "garment_type")).to eq("Jutti")
      expect(response.parsed_body.dig("data", "image", "signed_id")).to be_present
      expect(response.parsed_body.dig("data", "display_image", "signed_id")).to eq(response.parsed_body.dig("data", "image", "signed_id"))
      expect(response.parsed_body.dig("data", "cover_image")).to include(
        "kind" => "original_item",
        "generated" => false,
        "clothing_item_id" => item.id
      )
      expect(response.parsed_body.dig("data", "image_polish", "status")).to eq("waiting_for_analysis")
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

    it "rejects unsafe metadata before it can enter an AI ranking request" do
      expect do
        post "/api/v1/clothing_items", params: {
          clothing_item: {
            image: uploaded_png,
            name: "<script>reveal()</script>",
            category: "top",
            subcategory: "t_shirt",
            style_tags: [ "ignore_previous_instructions" ]
          }
        }, headers: auth_headers(user)
      end.not_to have_enqueued_job(AnalyzeClothingItemJob)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("clothing_items.create_failed"))
    end

    it "rejects an exact duplicate image for the same user's active wardrobe" do
      post "/api/v1/clothing_items", params: {
        clothing_item: { image: uploaded_png("first.png"), name: "First item" }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:created)

      expect do
        post "/api/v1/clothing_items", params: {
          clothing_item: { image: uploaded_png("different-name.png"), name: "Duplicate item" }
        }, headers: auth_headers(user)
      end.not_to change(user.clothing_items, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("clothing_items.duplicate_image"))
    end

    it "allows the same image for different users" do
      other_user = create(:user)
      post "/api/v1/clothing_items", params: {
        clothing_item: { image: uploaded_png("first.png") }
      }, headers: auth_headers(user)

      expect do
        post "/api/v1/clothing_items", params: {
          clothing_item: { image: uploaded_png("second.png") }
        }, headers: auth_headers(other_user)
      end.to change(other_user.clothing_items, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "allows re-upload after the original item is discarded" do
      post "/api/v1/clothing_items", params: {
        clothing_item: { image: uploaded_png("first.png") }
      }, headers: auth_headers(user)
      user.clothing_items.last.discard!

      expect do
        post "/api/v1/clothing_items", params: {
          clothing_item: { image: uploaded_png("replacement.png") }
        }, headers: auth_headers(user)
      end.to change(user.clothing_items, :count).by(1)

      expect(response).to have_http_status(:created)
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
          garment_type: "Polo shirt",
          category: "top",
          subcategory: "polo",
          primary_color: "navy",
          cultural_tags: [ "western" ],
          formality_score: 4
        }
      }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(item.reload.name).to eq("Navy textured polo")
      expect(item.primary_color).to eq("navy")
      expect(item.garment_type).to eq("Polo shirt")
      expect(item.cultural_tags).to eq([ "western" ])
    end

    it "schedules analysis when the image is replaced" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, status: "ready")

      expect do
        patch "/api/v1/clothing_items/#{item.id}", params: {
          clothing_item: { image: uploaded_png("replacement.png") }
        }, headers: auth_headers(user)
      end.to have_enqueued_job(AnalyzeClothingItemJob).with(item.id)

      expect(response).to have_http_status(:ok)
      expect(item.reload).to be_processing
    end

    it "rejects replacement with another active item's image" do
      existing_item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      existing_item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "existing.png", content_type: "image/png")
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)

      expect do
        patch "/api/v1/clothing_items/#{item.id}", params: {
          clothing_item: { image: uploaded_png("duplicate.png") }
        }, headers: auth_headers(user)
      end.not_to have_enqueued_job(AnalyzeClothingItemJob)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("clothing_items.duplicate_image"))
      expect(item.reload.image).not_to be_attached
    end

    it "allows replacing an item with its own image bytes" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "existing.png", content_type: "image/png")

      expect do
        patch "/api/v1/clothing_items/#{item.id}", params: {
          clothing_item: { image: uploaded_png("same-item.png") }
        }, headers: auth_headers(user)
      end.to have_enqueued_job(AnalyzeClothingItemJob).with(item.id)

      expect(response).to have_http_status(:ok)
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
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "polo.png", content_type: "image/png")

      expect do
        post "/api/v1/clothing_items/#{item.id}/reanalyze", headers: auth_headers(user)
      end.to have_enqueued_job(AnalyzeClothingItemJob).with(item.id)

      expect(response).to have_http_status(:ok)
      expect(item.reload).to be_processing
    end


    it "requires an attached image" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe, status: "ready")

      expect do
        post "/api/v1/clothing_items/#{item.id}/reanalyze", headers: auth_headers(user)
      end.not_to have_enqueued_job(AnalyzeClothingItemJob)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("clothing_items.image_required"))
      expect(item.reload).to be_ready
    end
  end

  describe "POST /api/v1/clothing_items/:id/polish" do
    it "queues a fresh polished catalog image while retaining the original" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "source.png", content_type: "image/png")
      item.save!
      original_blob = item.image.blob

      expect do
        post "/api/v1/clothing_items/#{item.id}/polish", headers: auth_headers(user)
      end.to have_enqueued_job(GenerateClothingItemPolishedImageJob).with(item.id, item.image_checksum)

      expect(response).to have_http_status(:accepted)
      expect(item.reload.image.blob).to eq(original_blob)
      expect(item.ai_metadata.dig("image_polish", "status")).to eq("queued")
    end


    it "does not enqueue a duplicate request while polishing is already queued" do
      item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
      item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "source.png", content_type: "image/png")
      item.save!
      item.update!(ai_metadata: { "image_polish" => { "status" => "queued", "source_checksum" => item.image_checksum } })

      expect do
        post "/api/v1/clothing_items/#{item.id}/polish", headers: auth_headers(user)
      end.not_to have_enqueued_job(GenerateClothingItemPolishedImageJob)

      expect(response).to have_http_status(:accepted)
    end
  end
end
