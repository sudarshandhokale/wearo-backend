require "rails_helper"

RSpec.describe ClothingAnalysis::Analyze do
  let(:item) { create(:clothing_item) }
  let(:provider) { instance_double(ClothingAnalysis::Providers::Openai) }

  it "returns normalized validated attributes and provider metadata" do
    allow(provider).to receive(:call).and_return(
      result: {
        name: "Navy tee",
        garment_type: "T-shirt",
        category: "top",
        subcategory: "tee",
        primary_color: "dark blue",
        secondary_colors: [],
        pattern: "solid",
        material: "cotton",
        season_tags: [ "summer" ],
        occasion_tags: [ "casual" ],
        style_tags: [ "minimal" ],
        cultural_tags: [],
        formality_score: 2,
        confidence: 0.88
      },
      metadata: {
        "provider" => "test",
        "model" => "test-model",
        "response_id" => "resp_analysis_1",
        "attempt_count" => 1,
        "usage" => { "input_tokens" => 80, "output_tokens" => 20, "total_tokens" => 100 }
      }
    )

    result = described_class.call(item, provider: provider)

    expect(result.attributes).to include("subcategory" => "t_shirt", "primary_color" => "navy")
    expect(result.metadata).to include("provider" => "test", "confidence" => 0.88)
    expect(item.ai_requests.last).to have_attributes(status: "succeeded", total_tokens: 100)
  end

  it "rejects a subcategory outside the normalized category" do
    allow(provider).to receive(:call).and_return(
      result: {
        name: nil,
        garment_type: "Boots",
        category: "top",
        subcategory: "boots",
        primary_color: nil,
        secondary_colors: [],
        pattern: nil,
        material: nil,
        season_tags: [],
        occasion_tags: [],
        style_tags: [],
        cultural_tags: [],
        formality_score: nil,
        confidence: nil
      },
      metadata: {}
    )

    expect { described_class.call(item, provider: provider) }.to raise_error(ClothingAnalysis::InvalidResultError)
  end
end
