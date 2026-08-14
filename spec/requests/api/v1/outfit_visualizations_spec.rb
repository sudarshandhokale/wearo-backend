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

  it "returns a stored flat lay without queueing or consuming the daily limit" do
    existing = create(:outfit_visualization, user: user, outfit: outfit, status: "ready")
    existing.update!(metadata: {
      "source_fingerprint" => Visualization::SourceFingerprint.call(existing)
    })
    existing.image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "flat-lay.png",
      content_type: "image/png"
    )
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:visualization_daily_limit, default: 10).and_return("1")

    expect do
      post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
        visualization: { mode: "flat_lay" }
      }, headers: auth_headers(user)
    end.not_to have_enqueued_job(GenerateOutfitVisualizationJob)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "id")).to eq(existing.id)
    expect(response.parsed_body.fetch("meta")).to include("reused" => true)
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

  it "returns a localized usage-limit failure that the client can act on" do
    visualization = create(
      :outfit_visualization,
      user: user,
      outfit: outfit,
      status: "failed",
      failure_code: "ai_usage_limit_reached",
      completed_at: Time.current
    )

    get "/api/v1/outfits/#{outfit.id}/visualizations/#{visualization.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to include(
      "status" => "failed",
      "failure_code" => "ai_usage_limit_reached",
      "failure_message" => I18n.t("visualizations.failures.ai_usage_limit_reached")
    )
    expect(response.parsed_body.dig("data", "retry_after")).to be_present
  end

  it "falls back to flat-lay and asks for a photo when try-on has no person reference" do
    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "try_on" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body.fetch("data")).to include(
      "mode" => "flat_lay",
      "metadata" => include(
        "requested_mode" => "try_on",
        "fallback_reason" => "person_reference_missing"
      ),
      "guidance" => include(
        "fallback_from_try_on" => true,
        "action" => "upload_full_body_photo"
      )
    )
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
    expect(response.parsed_body.dig("data", "guidance")).to include(
      "personalized" => true,
      "profile_photo_available" => true,
      "action" => nil
    )
  end

  it "enforces the configured try-on daily limit separately" do
    user.full_body_image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "full-body.png",
      content_type: "image/png"
    )
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:try_on_visualization_daily_limit, default: 1).and_return("1")
    create(:outfit_visualization, user: user, outfit: outfit, mode: "try_on")

    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "try_on" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("visualizations.daily_limit_reached"))
  end

  it "can disable try-on generation with a zero daily limit" do
    user.full_body_image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "full-body.png",
      content_type: "image/png"
    )
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:try_on_visualization_daily_limit, default: 1).and_return("0")

    post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
      visualization: { mode: "try_on" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "message")).to eq(I18n.t("visualizations.daily_limit_reached"))
  end

  it "stores and reuses try-on separately from the flat lay" do
    user.full_body_image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "full-body.png",
      content_type: "image/png"
    )
    existing = create(:outfit_visualization, user: user, outfit: outfit, mode: "try_on", status: "ready")
    existing.update!(metadata: {
      "source_fingerprint" => Visualization::SourceFingerprint.call(existing)
    })
    existing.image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "try-on.png",
      content_type: "image/png"
    )

    expect do
      post "/api/v1/outfits/#{outfit.id}/visualizations", params: {
        visualization: { mode: "try_on" }
      }, headers: auth_headers(user)
    end.not_to have_enqueued_job(GenerateOutfitVisualizationJob)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "id")).to eq(existing.id)
    expect(response.parsed_body.dig("data", "mode")).to eq("try_on")
    expect(response.parsed_body.fetch("meta")).to include("reused" => true)
  end

  it "does not expose another user's outfit" do
    post "/api/v1/outfits/#{create(:outfit).id}/visualizations", params: {
      visualization: { mode: "flat_lay" }
    }, headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end
end
