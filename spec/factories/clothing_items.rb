FactoryBot.define do
  factory :clothing_item do
    user
    wardrobe { user.wardrobe }
    name { "Navy polo" }
    category { "top" }
    subcategory { "polo" }
    primary_color { "navy" }
    secondary_colors { [] }
    pattern { "solid" }
    material { "cotton" }
    season_tags { [ "summer" ] }
    occasion_tags { [ "casual" ] }
    style_tags { [ "classic" ] }
    formality_score { 4 }
    status { "ready" }
  end
end
