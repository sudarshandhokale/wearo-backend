require "rails_helper"

RSpec.describe Visualization::Request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:outfit) { create(:outfit, user: user) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "queues a flat-lay visualization when the outfit has source item images" do
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
    create(:outfit_item, outfit: outfit, clothing_item: item, role: item.category)

    expect do
      result = described_class.call(user: user, outfit: outfit, mode: "flat_lay", auto: true)

      expect(result).to have_attributes(reused: false, queued: true)
      expect(result.visualization).to have_attributes(mode: "flat_lay", status: "queued")
    end.to have_enqueued_job(GenerateOutfitVisualizationJob)
      .and change(user.outfit_visualizations, :count).by(1)
  end

  it "does not fail when the outfit has no source item images" do
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    create(:outfit_item, outfit: outfit, clothing_item: item, role: item.category)

    expect do
      result = described_class.call(user: user, outfit: outfit, mode: "flat_lay", auto: true)

      expect(result).to have_attributes(visualization: nil, reused: false, queued: false)
    end.not_to have_enqueued_job(GenerateOutfitVisualizationJob)
  end

  it "falls back from try-on to flat-lay when no person reference exists" do
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
    create(:outfit_item, outfit: outfit, clothing_item: item, role: item.category)

    result = described_class.call(user: user, outfit: outfit, mode: "try_on")

    expect(result.visualization).to have_attributes(mode: "flat_lay")
    expect(result.visualization.metadata).to include(
      "requested_mode" => "try_on",
      "fallback_reason" => "person_reference_missing"
    )
  end

  it "reuses an in-progress visualization with the same source fingerprint" do
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe)
    item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
    create(:outfit_item, outfit: outfit, clothing_item: item, role: item.category)
    existing = described_class.call(user: user, outfit: outfit, mode: "flat_lay").visualization

    expect do
      result = described_class.call(user: user, outfit: outfit, mode: "flat_lay")

      expect(result).to have_attributes(visualization: existing, reused: true, queued: false)
    end.not_to change(user.outfit_visualizations, :count)
  end
end
