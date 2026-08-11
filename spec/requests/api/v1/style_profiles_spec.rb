require "rails_helper"

RSpec.describe "API v1 style profile", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/style_profile" do
    it "returns the current user's style profile" do
      user.style_profile.update!(preferred_styles: [ "classic" ])
      other_user = create(:user)
      other_user.style_profile.update!(preferred_styles: [ "streetwear" ])

      get "/api/v1/style_profile", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(user.style_profile.id)
      expect(response.parsed_body.dig("data", "preferred_styles")).to eq([ "classic" ])
    end

    it "requires authentication" do
      get "/api/v1/style_profile"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/style_profile" do
    it "updates flexible preference fields" do
      patch "/api/v1/style_profile", params: {
        style_profile: {
          preferred_styles: [ "minimal", "smart_casual" ],
          preferred_colors: [ "navy", "white" ],
          disliked_colors: [ "neon_green" ],
          fit_preferences: { tops: "regular", bottoms: "straight" },
          additional_preferences: { notes: "No large logos" },
          onboarding_completed: true
        }
      }, headers: auth_headers(user)

      profile = user.style_profile.reload
      expect(response).to have_http_status(:ok)
      expect(profile.preferred_styles).to eq([ "minimal", "smart_casual" ])
      expect(profile.preferred_colors).to eq([ "navy", "white" ])
      expect(profile.fit_preferences).to eq("tops" => "regular", "bottoms" => "straight")
      expect(profile.onboarding_completed).to be(true)
    end
  end
end
