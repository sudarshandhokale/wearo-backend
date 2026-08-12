require "rails_helper"

RSpec.describe Stylist::Providers::Openai do
  let(:endpoint) { "https://api.openai.test/v1/responses" }
  let(:provider) { described_class.new(api_key: "test-key", model: "test-model", endpoint: endpoint) }
  let(:candidates) do
    [
      {
        candidate_id: 1,
        score: 91,
        items: [ { role: "top", clothing_item_id: 10, primary_color: "navy" } ]
      }
    ]
  end

  it "sends only compact candidates with a strict ranking schema" do
    request = stub_request(:post, endpoint).with do |http_request|
      body = JSON.parse(http_request.body)
      user_content = JSON.parse(body.dig("input", 1, "content"))

      http_request.headers["Authorization"] == "Bearer test-key" &&
        body.dig("text", "format", "strict") == true &&
        user_content.fetch("candidates").length == 1
    end.to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "resp_stylist_1",
        output: [
          {
            type: "message",
            content: [
              {
                type: "output_text",
                text: { rankings: [ { candidate_id: 1, explanation: "Balanced and appropriate." } ] }.to_json
              }
            ]
          }
        ],
        usage: { input_tokens: 120, output_tokens: 30 }
      }.to_json
    )

    result = provider.call(prompt: "Dinner", context: { "occasion" => "dinner" }, candidates: candidates)

    expect(request).to have_been_requested.once
    expect(result[:rankings]).to eq([ { "candidate_id" => 1, "explanation" => "Balanced and appropriate." } ])
    expect(result[:metadata]).to include("provider" => "openai", "model" => "test-model")
  end

  it "raises a provider error for an unsuccessful response" do
    stub_request(:post, endpoint).to_return(status: 503)

    expect do
      provider.call(prompt: "Dinner", context: {}, candidates: candidates)
    end.to raise_error(Stylist::ProviderError)
  end
end
