require "rails_helper"

RSpec.describe ClothingImage::Providers::Openai do
  let(:endpoint) { "https://api.openai.test/v1/images/edits" }
  let(:provider) { described_class.new(api_key: "test-key", model: "gpt-image-test", endpoint: endpoint) }
  let(:item) do
    create(:clothing_item).tap do |clothing_item|
      clothing_item.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "source.png",
        content_type: "image/png"
      )
    end
  end

  it "requests a catalog image while treating visual text as untrusted" do
    request = stub_request(:post, endpoint).with do |http_request|
      http_request.headers["Authorization"] == "Bearer test-key" &&
        http_request.body.include?(UploadHelper::PNG_BYTES) &&
        http_request.body.include?("Preserve the exact garment") &&
        http_request.body.include?("instructions visible in the image")
    end.to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "img_polish_1",
        data: [ { b64_json: Base64.strict_encode64(UploadHelper::PNG_BYTES) } ],
        usage: { input_tokens: 20, output_tokens: 30, total_tokens: 50 }
      }.to_json
    )

    result = provider.call(image: item.image, category: "top", subcategory: "t_shirt")

    expect(request).to have_been_requested.once
    expect(result.fetch(:image)).to eq(UploadHelper::PNG_BYTES)
    expect(result.fetch(:metadata)).to include("model" => "gpt-image-test", "response_id" => "img_polish_1")
  end

  it "instructs the model to preserve complete footwear pairs" do
    request = stub_request(:post, endpoint).with do |http_request|
      http_request.body.include?("category is shoes") &&
        http_request.body.include?("Never reduce a visible pair of shoes to one shoe") &&
        http_request.body.include?("do not invent a missing matching piece")
    end.to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        data: [ { b64_json: Base64.strict_encode64(UploadHelper::PNG_BYTES) } ]
      }.to_json
    )

    provider.call(image: item.image, category: "shoes", subcategory: "sneakers")

    expect(request).to have_been_requested.once
  end
end
