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

    result = provider.call(prompt: "Dinner", context: { "occasion" => "dinner" }, candidates: candidates, user_id: 123)

    expect(request).to have_been_requested.once
    expect(result[:rankings]).to eq([ { "candidate_id" => 1, "explanation" => "Balanced and appropriate." } ])
    expect(result[:metadata]).to include("provider" => "openai", "model" => "test-model")
  end

  it "raises a provider error for an unsuccessful response" do
    stub_request(:post, endpoint).to_return(status: 503)

    expect do
      provider.call(prompt: "Dinner", context: {}, candidates: candidates, user_id: 123)
    end.to raise_error(Stylist::ProviderError)
  end

  it "retries a transient response and reports the attempt count" do
    stub_request(:post, endpoint).to_return(
      { status: 503 },
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          id: "resp_retry",
          output: [
            {
              type: "message",
              content: [ { type: "output_text", text: { rankings: [ { candidate_id: 1, explanation: "Ready." } ] }.to_json } ]
            }
          ],
          usage: { input_tokens: 10, output_tokens: 5, total_tokens: 15 }
        }.to_json
      }
    )

    result = provider.call(prompt: "Dinner", context: {}, candidates: candidates, user_id: 123)

    expect(result.dig(:metadata, "attempt_count")).to eq(2)
    expect(a_request(:post, endpoint)).to have_been_made.twice
  end

  it "rejects a non-HTTPS provider endpoint" do
    insecure_provider = described_class.new(api_key: "test-key", model: "test-model", endpoint: "http://api.openai.test/v1/responses")

    expect do
      insecure_provider.call(prompt: "Dinner", context: {}, candidates: candidates, user_id: 123)
    end.to raise_error(Stylist::ProviderError)
  end
end
