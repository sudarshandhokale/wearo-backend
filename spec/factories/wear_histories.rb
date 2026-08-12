FactoryBot.define do
  factory :wear_history do
    user
    outfit { association :outfit, user: user }
    worn_on { Date.current }
    occasion { "casual" }
    context { {} }
  end
end
