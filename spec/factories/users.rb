FactoryBot.define do
  factory :user do
    first_name { "Alex" }
    last_name { "Taylor" }
    sequence(:email) { |n| "alex#{n}@example.com" }
    password { "password123" }
    timezone { "America/New_York" }
    country_code { "US" }
    preferred_city { "New York" }
    accept_terms { true }
    accept_privacy { true }
    accept_ai_processing { true }
    confirm_adult { true }
    confirmed_at { Time.current }
  end
end
