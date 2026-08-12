require "rails_helper"

RSpec.describe "API v1 private media", type: :request do
  let(:user) { create(:user) }
  let(:item) do
    create(:clothing_item, user: user, wardrobe: user.wardrobe).tap do |record|
      record.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "item.png",
        content_type: "image/png"
      )
    end
  end

  it "serves an owned blob to an authenticated user" do
    get "/api/v1/media/#{item.image.blob.signed_id}", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end

  it "does not expose another user's blob" do
    get "/api/v1/media/#{item.image.blob.signed_id}", headers: auth_headers(create(:user))

    expect(response).to have_http_status(:not_found)
  end

  it "requires authentication" do
    get "/api/v1/media/#{item.image.blob.signed_id}"

    expect(response).to have_http_status(:unauthorized)
  end
end
