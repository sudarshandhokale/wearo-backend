require "rails_helper"

RSpec.describe "API v1 styling plans", type: :request do
  let(:user) { create(:user) }

  before do
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "one_piece", subcategory: "dress")
    allow(ExternalContext::Fetch).to receive(:call).and_return(
      ExternalContext::Result.new(city: "Paris", country_code: "FR", weather: [])
    )
  end

  it "creates a seven-day week plan with a compact packing summary" do
    post "/api/v1/styling_plans", params: {
      styling_plan: { plan_type: "week", city: "Paris", start_date: "2026-08-17", end_date: "2026-08-23" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    body = response.parsed_body.fetch("data")
    expect(body.fetch("entries").length).to eq(7)
    expect(body.dig("packing_summary", "days")).to eq(7)
    expect(body.dig("packing_summary", "unique_item_count")).to eq(1)
    expect(body.dig("packing_summary", "total_packed_quantity")).to eq(1)
    expect(body.dig("packing_summary", "items", 0, "quantity")).to eq(1)
    expect(body.dig("packing_summary", "items", 0, "wear_count")).to eq(7)
  end

  it "counts reused garments once while reporting how many days they are worn" do
    user.clothing_items.update_all(status: "analysis_failed")
    pants = create(:clothing_item, user: user, wardrobe: user.wardrobe, name: "Travel pants", category: "bottom", subcategory: "trousers")
    3.times do |index|
      create(:clothing_item, user: user, wardrobe: user.wardrobe, name: "Top #{index + 1}", category: "top", subcategory: "t_shirt")
    end

    post "/api/v1/styling_plans", params: {
      styling_plan: { plan_type: "vacation", city: "Paris", start_date: "2026-08-17", end_date: "2026-08-19" }
    }, headers: auth_headers(user)

    summary = response.parsed_body.dig("data", "packing_summary")
    pants_summary = summary.fetch("items").find { |item| item["clothing_item_id"] == pants.id }
    bottom_summary = summary.fetch("categories").find { |category| category["category"] == "bottom" }
    top_summary = summary.fetch("categories").find { |category| category["category"] == "top" }

    expect(response).to have_http_status(:created)
    expect(pants_summary).to include("quantity" => 1, "wear_count" => 3, "category_label" => "Bottom")
    expect(bottom_summary).to include("quantity" => 1, "wear_count" => 3)
    expect(top_summary).to include("quantity" => 3, "wear_count" => 3)
    expect(summary).to include("unique_item_count" => 4, "total_packed_quantity" => 4)
  end

  it "rejects a plan longer than sixteen days" do
    post "/api/v1/styling_plans", params: {
      styling_plan: { plan_type: "vacation", start_date: "2026-08-01", end_date: "2026-08-20" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("styling_plans.invalid_date_range"))
  end

  it "creates a vacation plan from a conversational itinerary" do
    start_on = Time.current.in_time_zone(user.timezone).to_date.next_occurring(:monday)

    post "/api/v1/styling_plans", params: {
      styling_plan: {
        prompt: "Pack for Paris next week. Monday museum, Tuesday dinner, Wednesday Coldplay concert."
      }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    body = response.parsed_body.fetch("data")
    expect(body).to include(
      "plan_type" => "vacation",
      "city" => "Paris",
      "start_date" => start_on.iso8601,
      "end_date" => (start_on + 6).iso8601
    )
    expect(body.dig("entries", 0, "context")).to include("itinerary" => "museum")
    expect(body.dig("entries", 1, "context")).to include("itinerary" => "dinner", "occasion" => "dinner")
    expect(body.dig("entries", 2, "context")).to include("itinerary" => "Coldplay concert", "occasion" => "concert")
  end

  it "respects user usage restrictions when choosing vacation outfits" do
    everyday_dress = user.clothing_items.first
    everyday_dress.update!(user_usage_tags: [ "everyday" ])
    travel_dress = create(
      :clothing_item,
      user: user,
      wardrobe: user.wardrobe,
      name: "Travel dress",
      category: "one_piece",
      subcategory: "dress",
      user_usage_tags: [ "travel" ]
    )

    post "/api/v1/styling_plans", params: {
      styling_plan: { plan_type: "vacation", city: "Paris", start_date: "2026-08-17", end_date: "2026-08-17" }
    }, headers: auth_headers(user)

    outfit_item_ids = response.parsed_body.dig("data", "entries", 0, "outfit", "items").pluck("clothing_item_id")
    expect(response).to have_http_status(:created)
    expect(outfit_item_ids).to include(travel_dress.id)
    expect(outfit_item_ids).not_to include(everyday_dress.id)
    expect(response.parsed_body.dig("data", "entries", 0, "context")).to include(
      "usage" => "travel",
      "usage_label" => "Travel"
    )
  end
end
