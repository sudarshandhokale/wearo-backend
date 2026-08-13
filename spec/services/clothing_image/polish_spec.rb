require "rails_helper"

RSpec.describe ClothingImage::Polish do
  let(:item) do
    create(:clothing_item).tap do |clothing_item|
      clothing_item.image.attach(
        io: StringIO.new(UploadHelper::PNG_BYTES),
        filename: "source.png",
        content_type: "image/png"
      )
    end
  end

  it "stores a separate polished image and records its source" do
    original_blob = item.image.blob
    provider = instance_double(ClothingImage::Providers::Openai)
    allow(provider).to receive(:call).with(
      image: item.image,
      category: item.category,
      subcategory: item.subcategory
    ).and_return(
      image: UploadHelper::PNG_BYTES,
      metadata: {
        "provider" => "openai",
        "model" => "gpt-image-2",
        "response_id" => "img_polish_1",
        "usage" => { "input_tokens" => 10, "output_tokens" => 20 },
        "attempt_count" => 1
      }
    )

    described_class.call(item, provider: provider)

    expect(item.image.blob).to eq(original_blob)
    expect(item.polished_image).to be_attached
    expect(item.ai_metadata.fetch("image_polish")).to include(
      "status" => "ready",
      "source_checksum" => original_blob.checksum,
      "response_id" => "img_polish_1"
    )
    expect(item.ai_requests.last).to have_attributes(operation: "clothing_image_polish", status: "succeeded", total_tokens: 30)
  end
end
