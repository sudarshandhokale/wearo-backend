require "rails_helper"

RSpec.describe ClothingAnalysis::Analyze do
  let(:item) { create(:clothing_item) }
  let(:provider) { instance_double(ClothingAnalysis::Providers::Openai) }

  it "returns normalized validated attributes and provider metadata" do
    allow(provider).to receive(:call).and_return(
      result: {
        name: "Navy tee",
        category: "top",
        subcategory: "tee",
        primary_color: "dark blue",
        secondary_colors: [],
        pattern: "solid",
        material: "cotton",
        season_tags: [ "summer" ],
        occasion_tags: [ "casual" ],
        style_tags: [ "minimal" ],
        formality_score: 2,
        confidence: 0.88
      },
      metadata: { "provider" => "test" }
    )

    result = described_class.call(item, provider: provider)

    expect(result.attributes).to include("subcategory" => "t_shirt", "primary_color" => "navy")
    expect(result.metadata).to eq("provider" => "test", "confidence" => 0.88)
  end

  it "rejects a subcategory outside the normalized category" do
    allow(provider).to receive(:call).and_return(
      result: {
        name: nil,
        category: "top",
        subcategory: "boots",
        primary_color: nil,
        secondary_colors: [],
        pattern: nil,
        material: nil,
        season_tags: [],
        occasion_tags: [],
        style_tags: [],
        formality_score: nil,
        confidence: nil
      },
      metadata: {}
    )

    expect { described_class.call(item, provider: provider) }.to raise_error(ClothingAnalysis::InvalidResultError)
  end
end
