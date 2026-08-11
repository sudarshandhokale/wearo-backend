FactoryBot.define do
  factory :user do
    first_name { "Alex" }
    last_name { "Taylor" }
    sequence(:email) { |n| "alex#{n}@example.com" }
    password { "password123" }
    timezone { "America/New_York" }
    country_code { "US" }
    preferred_city { "New York" }
  end
end
