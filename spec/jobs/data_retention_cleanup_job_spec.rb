require "rails_helper"

RSpec.describe DataRetentionCleanupJob do
  it "removes abandoned registrations, expired denylist records, and stale failures" do
    abandoned = create(:user, confirmed_at: nil, created_at: 8.days.ago)
    active = create(:user, confirmed_at: nil, created_at: 1.day.ago)
    expired_denylist = JwtDenylist.create!(jti: SecureRandom.uuid, exp: 1.day.ago)
    stale_visualization = create(:outfit_visualization, status: "failed", updated_at: 8.days.ago)

    described_class.perform_now

    expect(User.where(id: abandoned.id)).not_to exist
    expect(User.where(id: active.id)).to exist
    expect(JwtDenylist.where(id: expired_denylist.id)).not_to exist
    expect(OutfitVisualization.where(id: stale_visualization.id)).not_to exist
  end
end
