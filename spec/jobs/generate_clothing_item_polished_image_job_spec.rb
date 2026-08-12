require "rails_helper"

RSpec.describe GenerateClothingItemPolishedImageJob, type: :job do
  let(:item) do
    create(:clothing_item, ai_metadata: { "image_polish" => { "status" => "queued" } }).tap do |clothing_item|
      clothing_item.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "source.png",
        content_type: "image/png"
      )
      clothing_item.save!
    end
  end

  it "polishes the current source image" do
    allow(ClothingImage::Polish).to receive(:call).with(item)

    described_class.perform_now(item.id, item.image_checksum)

    expect(ClothingImage::Polish).to have_received(:call).with(item)
  end

  it "ignores a stale job after the source image changes" do
    allow(ClothingImage::Polish).to receive(:call)

    described_class.perform_now(item.id, "old-checksum")

    expect(ClothingImage::Polish).not_to have_received(:call)
  end

  it "records a polish failure without changing analysis readiness" do
    allow(ClothingImage::Polish).to receive(:call).and_raise(ClothingImage::ProviderError)

    described_class.perform_now(item.id, item.image_checksum)

    item.reload
    expect(item).to be_ready
    expect(item.ai_metadata.dig("image_polish", "status")).to eq("failed")
    expect(item.ai_metadata.dig("image_polish", "error", "code")).to eq("image_polish_failed")
  end
end
