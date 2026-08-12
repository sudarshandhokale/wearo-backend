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
      expect(body.dig("recommendation", "status")).to eq("completed")
      expect(body.dig("recommendation", "ranking_source")).to eq("ai")
      expect(body.fetch("outfits").length).to eq(3)
      expect(response_item_ids).to all(be_in(owned_items.map(&:id)))
      expect(response_item_ids).not_to include(other_item.id)
      expect(user.recommendation_requests.last.outfits.count).to eq(3)
    end

    it "recommends a one-piece outfit without requiring shoes" do
      dress = create(
        :clothing_item,
        user: user,
        wardrobe: user.wardrobe,
        category: "one_piece",
        subcategory: "dress",
        primary_color: "navy",
        status: "ready"
      )

      post "/api/v1/stylist/recommendations", params: {
        prompt: "Dinner with friends tonight"
      }, headers: auth_headers(user)

      body = response.parsed_body.dig("data")
      expect(response).to have_http_status(:created)
      expect(body.dig("outfits", 0, "items").pluck("role")).to eq([ "one_piece" ])
      expect(body.dig("outfits", 0, "items", 0, "clothing_item_id")).to eq(dress.id)
      expect(body.fetch("suggestions")).to include(
        hash_including("key" => "add_shoes", "role" => "shoes"),
        hash_including("key" => "add_accessory", "role" => "accessory")
      )
    end

    it "returns actionable rain advice when protection is not cataloged" do
      create(
        :clothing_item,
        user: user,
        wardrobe: user.wardrobe,
        category: "one_piece",
        subcategory: "dress",
        status: "ready"
      )
      allow(ExternalContext::Fetch).to receive(:call).and_return(
        ExternalContext::Result.new(
          city: "Berlin",
          country_code: "DE",
          weather: [ { "date" => Date.current.iso8601, "condition" => "rain", "precipitation_probability" => 85 } ]
        )
      )

      post "/api/v1/stylist/recommendations", params: {
        prompt: "Casual plans today",
        city: "Berlin"
      }, headers: auth_headers(user)

      suggestion = response.parsed_body.dig("data", "suggestions").find { |item| item["key"] == "bring_rain_protection" }
      expect(response).to have_http_status(:created)
      expect(suggestion).to include(
        "type" => "weather",
        "priority" => "essential",
        "action" => "bring",
        "suggested_subcategories" => %w[umbrella raincoat water_resistant_shoes]
      )
      expect(suggestion.fetch("question")).to be_present
    end


    it "recommends a complete set without requiring separates" do
      matching_set = create(
        :clothing_item,
        user: user,
        wardrobe: user.wardrobe,
        category: "set",
        subcategory: "co_ord",
        primary_color: "green",
        status: "ready"
      )

      post "/api/v1/stylist/recommendations", params: {
        prompt: "Casual lunch with friends"
      }, headers: auth_headers(user)

      body = response.parsed_body.dig("data")
      expect(response).to have_http_status(:created)
      expect(body.dig("outfits", 0, "items").pluck("role")).to eq([ "set" ])
      expect(body.dig("outfits", 0, "items", 0, "clothing_item_id")).to eq(matching_set.id)
    end


    it "recommends an individual saree with an ethnic blouse" do
      saree = create(
        :clothing_item,
        user: user,
        wardrobe: user.wardrobe,
        category: "drape",
        subcategory: "saree",
        primary_color: "red",
        status: "ready"
      )
      blouse = create(
        :clothing_item,
        user: user,
        wardrobe: user.wardrobe,
        category: "top",
        subcategory: "ethnic_blouse",
        primary_color: "gold",
        status: "ready"
      )

      post "/api/v1/stylist/recommendations", params: {
        prompt: "Saree outfit for a wedding reception"
      }, headers: auth_headers(user)

      body = response.parsed_body.dig("data")
      expect(response).to have_http_status(:created)
      expect(body.dig("context", "occasion")).to eq("wedding")
      expect(body.dig("outfits", 0, "items").pluck("role")).to eq(%w[drape top])
      expect(body.dig("outfits", 0, "items").pluck("clothing_item_id")).to contain_exactly(saree.id, blouse.id)
    end

    it "returns localized details when required wardrobe roles are missing" do
      create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "top", subcategory: "polo", status: "ready")

      post "/api/v1/stylist/recommendations", params: { prompt: "What should I wear today?" }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.insufficient_wardrobe"))
      expect(response.parsed_body.dig("error", "details", "missing_roles")).to contain_exactly("bottom", "one_piece", "drape", "set")
      expect(response.parsed_body.dig("error", "details", "required_combinations")).to eq([ %w[top bottom], %w[one_piece], %w[drape top], %w[set] ])
      expect(user.recommendation_requests.last).to have_attributes(
        status: "failed",
        failure_code: "insufficient_wardrobe_error"
      )
    end

    it "rejects a blank prompt with a localized message" do
      post "/api/v1/stylist/recommendations", params: { prompt: " " }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.invalid_prompt"))
    end

    it "rejects an oversized prompt without storing it" do
      expect do
        post "/api/v1/stylist/recommendations", params: { prompt: "a" * 1_001 }, headers: auth_headers(user)
      end.not_to change(user.recommendation_requests, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.invalid_prompt"))
    end

    it "enforces the configured daily recommendation limit" do
      allow(AppConfig).to receive(:fetch).and_call_original
      allow(AppConfig).to receive(:fetch).with(:stylist_daily_recommendation_limit, default: 50).and_return("1")
      create(:recommendation_request, user: user)

      post "/api/v1/stylist/recommendations", params: { prompt: "Dinner" }, headers: auth_headers(user)

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("stylist.recommendation_limit_reached"))
    end

    it "requires authentication" do
      post "/api/v1/stylist/recommendations", params: { prompt: "Dinner" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a localized generic error without exposing internal exception details" do
      allow(Stylist::Recommend).to receive(:call).and_raise(StandardError, "sensitive internal details")

      post "/api/v1/stylist/recommendations", params: { prompt: "Dinner" }, headers: auth_headers(user)

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("errors.messages.internal_server_error"))
      expect(response.body).not_to include("sensitive internal details")
    end
  end
end
