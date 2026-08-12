require "rails_helper"

RSpec.describe "API v1 outfit visualizations", type: :request do
  let(:user) { create(:user) }
  let(:outfit) { create(:outfit, user: user) }

  before do
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
    create(:outfit_item, outfit: outfit, clothing_item: item)
  end

  it "queues an owned flat-lay visualization" do
    expect do
      post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
        visualization: { mode: "flat_lay" }
      }, headers: auth_headers(user)
    end.to have_enqueued_job(GenerateOutfitVisualizationJob)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body.dig("data", "status")).to eq("queued")
  end

  it "uses flat-lay mode when the mode is omitted" do
    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body.dig("data", "mode")).to eq("flat_lay")
  end

  it "enforces the configured daily queue limit" do
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:visualization_daily_limit, default: 10).and_return("1")
    create(:outfit_visualization, user: user, outfit: outfit)

    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "flat_lay" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("visualizations.daily_limit_reached"))
  end

  it "requires a person reference for try-on mode" do
    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "try_on" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("visualizations.create_failed"))
  end

  it "uses the saved full-body profile image for try-on mode" do
    user.full_body_image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "full-body.png",
      content_type: "image/png"
    )

    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "try_on" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:accepted)
    expect(OutfitVisualization.last.person_reference_image.blob).to eq(user.full_body_image.blob)
  end

  it "does not expose another user's outfit" do
    post "/api/v1/outfits/#{create(:outfit).id}/visualizations", params: {
      visualization: { mode: "flat_lay" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end
end
