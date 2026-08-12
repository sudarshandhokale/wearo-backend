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


  it "normalizes a dress category as a one-piece garment" do
    result = described_class.call(category: "Full Dress", subcategory: "dress")

    expect(result).to include("category" => "one_piece", "subcategory" => "dress")
  end


  it "infers inclusive garment categories from common item names" do
    expect(described_class.call(category: "Blouse")).to include("category" => "top", "subcategory" => "blouse")
    expect(described_class.call(category: "Skirt")).to include("category" => "bottom", "subcategory" => "skirt")
    expect(described_class.call(category: "Heels")).to include("category" => "shoes", "subcategory" => "heels")
    expect(described_class.call(category: "Saree")).to include("category" => "drape", "subcategory" => "saree")
  end


  it "normalizes complete and individual Indian traditional garments" do
    expect(described_class.call(category: "Kurta")).to include("category" => "top", "subcategory" => "kurta")
    expect(described_class.call(category: "Lehenga Skirt")).to include("category" => "bottom", "subcategory" => "lehenga_skirt")
    expect(described_class.call(category: "Kurta Pajama")).to include("category" => "set", "subcategory" => "kurta_set")
    expect(described_class.call(category: "Jutti")).to include("category" => "shoes", "subcategory" => "jutti")
  end

  it "normalizes representative garments from different clothing traditions" do
    expect(described_class.call(category: "Hanbok")).to include("category" => "set", "subcategory" => "hanbok_set")
    expect(described_class.call(category: "Abaya")).to include("category" => "one_piece", "subcategory" => "abaya")
    expect(described_class.call(category: "Kilt")).to include("category" => "bottom", "subcategory" => "kilt")
    expect(described_class.call(category: "Sarong")).to include("category" => "drape", "subcategory" => "sarong")
  end

  it "preserves an unknown local garment name while using a universal fallback" do
    result = described_class.call(
      category: "top",
      subcategory: "Huipil",
      garment_type: "Huipil",
      cultural_tags: [ "Maya Traditional", "Guatemalan" ]
    )

    expect(result).to include(
      "category" => "top",
      "subcategory" => "other",
      "garment_type" => "Huipil",
      "cultural_tags" => [ "maya_traditional", "guatemalan" ]
    )
  end
end
