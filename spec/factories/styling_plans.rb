FactoryBot.define do
  factory :styling_plan do
    user
    plan_type { "week" }
    status { "completed" }
    city { "New York" }
    country_code { "US" }
    start_date { Date.current.next_occurring(:monday) }
    end_date { start_date + 6.days }
    weather_context { [] }
    events_context { [] }
    packing_summary { {} }
  end
end
