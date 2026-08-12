FactoryBot.define do
  factory :outfit_feedback do
    user
    outfit { association :outfit, user: user }
    reaction { "liked" }
    reason { nil }
    notes { "Comfortable and easy to wear" }
  end
end
