FactoryBot.define do
  factory :outfit_visualization do
    user
    outfit do
      association(:outfit, user: user).tap do |record|
        item = association(:clothing_item, user: user, wardrobe: user.wardrobe)
        item.image.attach(io: StringIO.new(UploadHelper::PNG_BYTES), filename: "item.png", content_type: "image/png")
        association(:outfit_item, outfit: record, clothing_item: item)
      end
    end
    mode { "flat_lay" }
    status { "queued" }
    metadata { {} }
  end
end
