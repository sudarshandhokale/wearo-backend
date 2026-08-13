require "rails_helper"

RSpec.describe ClothingAnalysis::Providers::Openai do
  let(:endpoint) { "https://api.openai.test/v1/responses" }
  let(:provider) { described_class.new(api_key: "test-key", model: "test-model", endpoint: endpoint) }
  let(:item) do
    create(:clothing_item).tap do |clothing_item|
      clothing_item.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "item.png",
        content_type: "image/png"
      )
    end
  end
  let(:analysis_result) do
    {
      name: "Navy T-shirt",
      garment_type: "T-shirt",
      category: "top",
      subcategory: "t_shirt",
      primary_color: "navy",
      secondary_colors: [],
      pattern: "solid",
      material: "cotton",
      fit: "regular",
      season_tags: [ "summer" ],
      occasion_tags: [ "casual" ],
      style_tags: [ "minimal" ],
      cultural_tags: [],
      formality_score: 2,
      confidence: 0.95
    }
  end

  it "sends image input with a strict schema and parses output" do
    request = stub_request(:post, endpoint).with do |http_request|
      body = JSON.parse(http_request.body)
      image_input = body.dig("input", 0, "content", 1)

      http_request.headers["Authorization"] == "Bearer test-key" &&
        body.dig("text", "format", "strict") == true &&
        body.dig("input", 0, "content", 0, "text").include?("meaningful catalog title") &&
        image_input["type"] == "input_image" &&
        image_input["image_url"].start_with?("data:image/png;base64,")
    end.to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "resp_123",
        output: [
          { type: "message", content: [ { type: "output_text", text: analysis_result.to_json } ] }
        ],
        usage: { input_tokens: 100, output_tokens: 50 }
      }.to_json
    )

    result = provider.call(image: item.image, user_id: item.user_id)

    expect(request).to have_been_requested.once
    expect(result[:result]).to include("subcategory" => "t_shirt")
    expect(result[:metadata]).to include("provider" => "openai", "model" => "test-model", "response_id" => "resp_123")
  end

  it "raises a provider error for unsuccessful responses" do
    stub_request(:post, endpoint).to_return(status: 503, body: "unavailable")

    expect { provider.call(image: item.image, user_id: item.user_id) }.to raise_error(ClothingAnalysis::ProviderError)
  end

  it "requires an API key" do
    unconfigured_provider = described_class.new(api_key: nil, model: "test-model", endpoint: endpoint)

    expect { unconfigured_provider.call(image: item.image, user_id: item.user_id) }.to raise_error(ClothingAnalysis::ConfigurationError)
  end
end
