require "rails_helper"

RSpec.describe "API v1 stylist recommendations", type: :request do
  let(:user) { create(:user) }

  before do
    allow(Stylist::RankRecommendations).to receive(:call) do |scored_combinations:, **|
      scored_combinations.sort_by { |combination| -combination.score }.first(3).map do |combination|
        Stylist::RankedCombination.new(
          items: combination.items,
          score: combination.score,
          score_breakdown: combination.score_breakdown,
          explanation: "A strong match for the requested occasion.",
          ranking_metadata: { "provider" => "test" }
        )
      end
    end
  end

  describe "POST /api/v1/stylist/recommendations" do
    it "persists and returns up to three outfits using only the current user's wardrobe" do
      owned_items = [
        create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", primary_color: "navy", status: "ready"),
        create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "shirt", primary_color: "white", status: "ready"),
        create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "jeans", primary_color: "navy", status: "ready"),
        create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "bottom", subcategory: "chinos", primary_color: "beige", status: "ready"),
        create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "shoes", subcategory: "sneakers", primary_color: "white", status: "ready")
      ]
      other_user = create(:user)
      other_item = create(:clothing_item, user: other_user, wardrobe: other_user.wardrobe, category: "top", subcategory: "shirt", status: "ready")

      expect do
        post "/api/v1/stylist/recommendations", params: {
          prompt: "Casual dinner with friends tonight"
        }, headers: auth_headers(user)
      end.to change(user.outfits, :count).by(3)

      body = response.parsed_body.dig("data")
      response_item_ids = body.fetch("outfits").flat_map { |outfit| outfit.fetch("items").pluck("clothing_item_id") }
      expect(response).to have_http_status(:created)
      expect(body.dig("context", "occasion")).to eq("dinner")
      expect(body.fetch("outfits").length).to eq(3)
      expect(response_item_ids).to all(be_in(owned_items.map(&:id)))
      expect(response_item_ids).not_to include(other_item.id)
    end

    it "returns localized details when required wardrobe roles are missing" do
      create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")

      post "/api/v1/stylist/recommendations", params: { prompt: "What should I wear today?" }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.insufficient_wardrobe"))
      expect(response.parsed_body.dig("error", "details", "missing_roles")).to contain_exactly("bottom", "shoes")
    end

    it "rejects a blank prompt with a localized message" do
      post "/api/v1/stylist/recommendations", params: { prompt: " " }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.invalid_prompt"))
    end

    it "requires authentication" do
      post "/api/v1/stylist/recommendations", params: { prompt: "Dinner" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
