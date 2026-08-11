require "rails_helper"

RSpec.describe StyleProfile, type: :model do
  subject(:style_profile) { build(:style_profile) }

  it { is_expected.to belong_to(:user) }
end
