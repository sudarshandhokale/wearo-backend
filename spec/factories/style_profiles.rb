FactoryBot.define do
  factory :style_profile do
    user
    preferred_styles { [ "minimal", "classic" ] }
    preferred_colors { [ "navy", "white" ] }
    disliked_colors { [ "orange" ] }
    fit_preferences { { "tops" => "regular" } }
    additional_preferences { { "avoid" => [ "large_logos" ] } }
    onboarding_completed { false }
  end
end
