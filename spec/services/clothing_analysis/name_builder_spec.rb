require "rails_helper"

RSpec.describe ClothingAnalysis::NameBuilder do
  it "replaces a generic jeans name with detected visual details" do
    name = described_class.call(
      proposed_name: "Jeans",
      attributes: {
        "category" => "bottom", "subcategory" => "jeans", "garment_type" => "Jeans",
        "primary_color" => "blue", "secondary_colors" => [], "pattern" => "solid", "material" => "denim"
      }
    )

    expect(name).to eq("Blue Denim Jeans")
  end

  it "uses pattern details without inventing a material" do
    name = described_class.call(
      proposed_name: "T-shirt",
      attributes: {
        "category" => "top", "subcategory" => "t_shirt", "garment_type" => "T-shirt",
        "primary_color" => "black", "secondary_colors" => [], "pattern" => "striped", "material" => nil
      }
    )

    expect(name).to eq("Black Striped T-shirt")
  end

  it "keeps an already descriptive model name" do
    name = described_class.call(
      proposed_name: "Navy Cotton Polo",
      attributes: { "primary_color" => "navy", "material" => "cotton" }
    )

    expect(name).to eq("Navy Cotton Polo")
  end
end
