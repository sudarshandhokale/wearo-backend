require "rails_helper"

RSpec.describe "API v1 health", type: :request do
  it "returns ok" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "success" => true,
      "data" => { "status" => "ok" },
      "meta" => nil
    )
  end

  it "reports readiness checks" do
    allow_any_instance_of(Api::V1::HealthController).to receive(:redis_ready?).and_return(true)

    get "/api/v1/health/readiness"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "status")).to eq("ready")
    expect(response.parsed_body.dig("data", "checks")).to eq(
      "database" => "ok",
      "redis" => "ok",
      "storage" => "ok",
      "workers" => "ok"
    )
  end
end
