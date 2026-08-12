require "rails_helper"

RSpec.describe Visualization::Providers::Openai do
  let(:endpoint) { "https://api.openai.test/v1/images/edits" }
  let(:provider) { described_class.new(api_key: "test-key", model: "gpt-image-test", endpoint: endpoint) }

  it "sends the saved profile image first for try-on visualization" do
    visualization = create(:outfit_visualization, mode: "flat_lay")
    visualization.user.full_body_image.attach(
      io: StringIO.new("profile-image-data"),
      filename: "profile.png",
      content_type: "image/png"
    )
    visualization.update!(mode: "try_on")

    request = stub_request(:post, endpoint).with do |http_request|
      http_request.headers["Authorization"] == "Bearer test-key" &&
        http_request.headers["Content-Type"].start_with?("multipart/form-data; boundary=") &&
        http_request.body.include?("profile-image-data") &&
        http_request.body.index("profile-image-data") < http_request.body.index(UploadHelper::PNG_BYTES)
    end.to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "img_123",
        data: [ { b64_json: Base64.strict_encode64(UploadHelper::PNG_BYTES) } ],
        usage: { input_tokens: 100, output_tokens: 50, total_tokens: 150 }
      }.to_json
    )

    result = provider.call(visualization: visualization)

    expect(request).to have_been_requested.once
    expect(result.fetch(:image)).to eq(UploadHelper::PNG_BYTES)
    expect(result.fetch(:metadata)).to include(
      "model" => "gpt-image-test",
      "reference_source" => "profile",
      "response_id" => "img_123"
    )
  end
end
