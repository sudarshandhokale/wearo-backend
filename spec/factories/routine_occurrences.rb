FactoryBot.define do
  factory :routine_occurrence do
    styling_routine
    user { styling_routine.user }
    scheduled_for { 1.day.from_now }
    status { "scheduled" }
  end
end
