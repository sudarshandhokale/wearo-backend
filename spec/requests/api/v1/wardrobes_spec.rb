require "rails_helper"

RSpec.describe "API v1 wardrobe", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/wardrobe" do
    it "returns the current user's default wardrobe" do
      other_user = create(:user)
      other_user.wardrobe.update!(name: "Other Wardrobe")

      get "/api/v1/wardrobe", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(user.wardrobe.id)
      expect(response.parsed_body.dig("data", "name")).to eq(Wardrobe::DEFAULT_NAME)
    end

    it "requires authentication" do
      get "/api/v1/wardrobe"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
