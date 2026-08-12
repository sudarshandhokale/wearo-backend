FactoryBot.define do
  factory :ai_request do
    user
    operation { "stylist_recommendation" }
    status { "succeeded" }
    provider { "openai" }
    model { "test-model" }
    input_tokens { 100 }
    output_tokens { 20 }
    total_tokens { 120 }
    attempt_count { 1 }
    completed_at { Time.current }
  end
end
