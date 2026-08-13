FactoryBot.define do
  factory :styling_routine do
    user
    name { "Office" }
    routine_type { "work" }
    days_of_week { [ 1, 2, 3, 4, 5 ] }
    local_time { "08:30" }
    usage { "work" }
    city_mode { "profile" }
    outfit_strategy { "separate" }
    recommendation_lead_minutes { 720 }
    reminder_enabled { false }
    active { true }
  end
end
