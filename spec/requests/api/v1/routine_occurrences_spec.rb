require "rails_helper"

RSpec.describe "API v1 routine occurrences", type: :request do
  it "returns today's generated routines with outfit details" do
    user = create(:user, timezone: "Europe/Berlin")
    routine = create(:styling_routine, user: user)
    outfit = create(:outfit, user: user)
    occurrence = create(:routine_occurrence, user: user, styling_routine: routine, outfit: outfit,
                                             scheduled_for: Time.current.in_time_zone(user.timezone).change(hour: 8), status: "generated")

    get "/api/v1/routine_occurrences/today", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", 0)).to include(
      "id" => occurrence.id, "status" => "generated", "status_label" => "Ready"
    )
    expect(response.parsed_body.dig("data", 0, "routine", "name")).to eq("Office")
    expect(response.parsed_body.dig("data", 0, "outfit", "id")).to eq(outfit.id)
  end
end
