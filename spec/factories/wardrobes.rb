FactoryBot.define do
  factory :wardrobe do
    user
    name { Wardrobe::DEFAULT_NAME }
  end
end
