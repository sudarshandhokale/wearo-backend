require "rails_helper"

RSpec.describe "API v1 styling routines", type: :request do
  let(:user) { create(:user, timezone: "Europe/Berlin") }

  it "creates, lists, updates, and deletes an owned routine" do
    allow(Routines::ScheduleOccurrences).to receive(:call)
    post "/api/v1/styling_routines", params: {
      styling_routine: {
        name: "Morning walk", routine_type: "walking", days_of_week: [ 1, 3, 5 ],
        local_time: "07:00", usage: "walking", city_mode: "profile"
      }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    routine_id = response.parsed_body.dig("data", "id")
    expect(response.parsed_body.fetch("data")).to include(
      "routine_type_label" => "Walking", "day_labels" => %w[Monday Wednesday Friday],
      "usage_label" => "Walking", "local_time" => "07:00", "recommendation_lead_minutes" => 660
    )

    patch "/api/v1/styling_routines/#{routine_id}", params: {
      styling_routine: { local_time: "07:30", reminder_enabled: true }
    }, headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to include("local_time" => "07:30", "reminder_enabled" => true)

    get "/api/v1/styling_routines", headers: auth_headers(user)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([ routine_id ])

    delete "/api/v1/styling_routines/#{routine_id}", headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
  end

  it "returns routine drafts without persisting them" do
    expect do
      post "/api/v1/styling_routines/drafts", params: {
        prompt: "Office weekdays at 8:30 and gym Tuesday Thursday at 6pm"
      }, headers: auth_headers(user)
    end.not_to change(StylingRoutine, :count)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("routine_type")).to contain_exactly("work", "workout")
  end

  it "does not expose another user's routine" do
    routine = create(:styling_routine)
    get "/api/v1/styling_routines/#{routine.id}", headers: auth_headers(user)
    expect(response).to have_http_status(:not_found)
  end
end
