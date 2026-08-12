require "rails_helper"

RSpec.describe Visualization::Generate do
  it "attaches the generated image and records AI usage" do
    visualization = create(:outfit_visualization, metadata: { "requested_mode" => "try_on" })
    provider = instance_double(Visualization::Providers::Openai)
    allow(provider).to receive(:call).and_return(
      image: UploadHelper::PNG_BYTES,
      metadata: {
        "provider" => "openai",
        "model" => "gpt-image-2",
        "usage" => { "input_tokens" => 10, "output_tokens" => 20 },
        "attempt_count" => 1
      }
    )

    described_class.call(visualization, provider: provider)

    expect(visualization).to be_ready
    expect(visualization.image).to be_attached
    expect(visualization.metadata).to include("requested_mode" => "try_on", "provider" => "openai")
    expect(visualization.ai_requests.last).to have_attributes(status: "succeeded", total_tokens: 30)
  end
end
