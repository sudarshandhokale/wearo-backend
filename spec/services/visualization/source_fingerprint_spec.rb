require "rails_helper"

RSpec.describe Visualization::SourceFingerprint do
  it "uses the person reference only for try-on fingerprints" do
    flat_lay = create(:outfit_visualization)
    user = flat_lay.user
    user.full_body_image.attach(
      io: StringIO.new(UploadHelper::PNG_BYTES),
      filename: "person.png",
      content_type: "image/png"
    )
    try_on = create(:outfit_visualization, user: user, outfit: flat_lay.outfit, mode: "try_on")
    original_flat_lay_fingerprint = described_class.call(flat_lay)
    original_try_on_fingerprint = described_class.call(try_on)

    user.full_body_image.attach(
      io: StringIO.new("different-person-image"),
      filename: "replacement.png",
      content_type: "image/png"
    )

    expect(described_class.call(flat_lay)).to eq(original_flat_lay_fingerprint)
    expect(described_class.call(try_on)).not_to eq(original_try_on_fingerprint)
  end
end
