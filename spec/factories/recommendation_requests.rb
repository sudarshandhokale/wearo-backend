FactoryBot.define do
  factory :recommendation_request do
    user
    prompt { "Casual dinner tonight" }
    context { { "occasion" => "dinner" } }
    wardrobe_suggestions { [] }
    status { "completed" }
    ranking_source { "deterministic" }
    completed_at { Time.current }
  end
end
