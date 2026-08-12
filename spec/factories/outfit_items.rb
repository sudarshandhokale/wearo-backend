FactoryBot.define do
  factory :outfit_item do
    outfit
    role { "top" }
    position { 0 }
    clothing_item do
      create(
        :clothing_item,
        user: outfit.user,
        wardrobe: outfit.user.wardrobe,
        category: role,
        subcategory: role == "top" ? "polo" : nil
      )
    end
  end
end
