require "rails_helper"

RSpec.describe "API rate limiting", type: :request do
  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.cache.store = previous_store
    Rack::Attack.reset!
  end

  it "limits repeated login attempts by IP" do
    8.times do
      post "/api/v1/auth/login", params: {
        user: { email: "missing@example.com", password: "wrong-password" }
      }
      expect(response).to have_http_status(:unauthorized)
    end

    post "/api/v1/auth/login", params: {
      user: { email: "missing@example.com", password: "wrong-password" }
    }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to be_present
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("errors.messages.rate_limited"))
  end
end
