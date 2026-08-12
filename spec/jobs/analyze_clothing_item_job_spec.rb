require "rails_helper"

RSpec.describe AnalyzeClothingItemJob, type: :job do
  let(:item) do
    create(:clothing_item, status: "processing").tap do |clothing_item|
      clothing_item.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "item.png",
        content_type: "image/png"
      )
    end
  end

  let(:attributes) do
    {
      "name" => "Navy cotton T-shirt",
      "garment_type" => "T-shirt",
      "category" => "top",
      "subcategory" => "t_shirt",
      "primary_color" => "navy",
      "secondary_colors" => [ "white" ],
      "pattern" => "solid",
      "material" => "cotton",
      "season_tags" => [ "summer" ],
      "occasion_tags" => [ "casual" ],
      "style_tags" => [ "minimal" ],
      "cultural_tags" => [],
      "formality_score" => 2
    }
  end

  it "persists successful analysis and marks the item ready" do
    result = ClothingAnalysis::AnalysisResult.new(
      attributes: attributes,
      metadata: { "provider" => "openai", "confidence" => 0.92 }
    )
    allow(ClothingAnalysis::Analyze).to receive(:call).with(item).and_return(result)

    expect do
      described_class.perform_now(item.id)
    end.to have_enqueued_job(GenerateClothingItemPolishedImageJob).with(item.id, item.image_checksum)

    item.reload
    expect(item).to be_ready
    expect(item.name).to eq("Navy cotton T-shirt")
    expect(item.subcategory).to eq("t_shirt")
    expect(item.ai_analyzed_at).to be_present
    expect(item.ai_metadata).to include("provider" => "openai", "confidence" => 0.92)
    expect(item.ai_metadata.dig("image_polish", "status")).to eq("queued")
    expect(item.ai_metadata.dig("image_polish", "source_checksum")).to eq(item.image_checksum)
  end

  it "marks the item failed when analysis raises an error" do
    allow(ClothingAnalysis::Analyze).to receive(:call).with(item).and_raise(ClothingAnalysis::ProviderError, "provider unavailable")

    described_class.perform_now(item.id)

    item.reload
    expect(item).to be_analysis_failed
    expect(item.ai_analyzed_at).to be_nil
    expect(item.ai_metadata.dig("error", "code")).to eq("analysis_failed")
  end

  it "does not analyze a discarded item" do
    allow(ClothingAnalysis::Analyze).to receive(:call)
    item.discard!

    described_class.perform_now(item.id)

    expect(ClothingAnalysis::Analyze).not_to have_received(:call)
  end
end
