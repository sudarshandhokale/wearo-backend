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
end
