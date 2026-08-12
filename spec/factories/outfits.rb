FactoryBot.define do
  factory :outfit do
    user
    prompt { "Casual dinner with friends" }
    occasion { "dinner" }
    context { { "formality" => "smart_casual", "activity" => "social" } }
    weather_context { {} }
    recommendation_score { 88.5 }
    explanation { "A balanced smart-casual outfit using complementary colors." }
    status { "recommended" }
    recommended_for { 1.day.from_now }
  end
end
