require "rails_helper"

RSpec.describe ClothingAnalysis::NormalizeResult do
  it "normalizes clothing aliases, colors, and tags" do
    result = described_class.call(
      name: "  Everyday Tee  ",
      category: "Tops",
      subcategory: "tee",
      primary_color: "Dark Blue",
      secondary_colors: [ "Grey", "grey" ],
      pattern: "Color Block",
      material: "Organic Cotton",
      season_tags: [ "Spring / Summer" ],
      occasion_tags: [ "Everyday Casual" ],
      style_tags: [ "Street Wear" ],
      formality_score: "2",
      confidence: "0.91"
    )

    expect(result).to include(
      "name" => "Everyday Tee",
      "category" => "top",
      "subcategory" => "t_shirt",
      "primary_color" => "navy",
      "secondary_colors" => [ "gray" ],
      "pattern" => "color_block",
      "material" => "organic_cotton",
      "formality_score" => 2,
      "confidence" => 0.91
    )
  end

  it "infers the category from a trainer subcategory alias" do
    result = described_class.call(subcategory: "trainer")

    expect(result).to include("category" => "shoes", "subcategory" => "sneakers")
  end
end
