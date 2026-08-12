require "rails_helper"

RSpec.describe Stylist::CompatibilityScorer do
  let(:user) { create(:user) }
  let(:style_profile) do
    user.style_profile.tap do |profile|
      profile.update!(preferred_colors: [ "navy", "white" ], disliked_colors: [ "orange" ], preferred_styles: [ "minimal" ])
    end
  end
  let(:context) { { "occasion" => "dinner", "formality" => "smart_casual", "season" => "summer" } }

  def combination_with(color)
    Stylist::Combination.new(items: {
      "top" => build_stubbed(:clothing_item, primary_color: color, occasion_tags: [ "dinner" ], season_tags: [ "summer" ], style_tags: [ "minimal" ], formality_score: 5),
      "bottom" => build_stubbed(:clothing_item, category: "bottom", subcategory: "jeans", primary_color: "navy", occasion_tags: [ "dinner" ], season_tags: [ "summer" ], style_tags: [ "minimal" ], formality_score: 5),
      "shoes" => build_stubbed(:clothing_item, category: "shoes", subcategory: "sneakers", primary_color: "white", occasion_tags: [ "dinner" ], season_tags: [ "summer" ], style_tags: [ "minimal" ], formality_score: 5)
    })
  end

  it "scores preferred combinations above disliked-color combinations" do
    preferred = described_class.call(combination: combination_with("white"), context: context, style_profile: style_profile)
    disliked = described_class.call(combination: combination_with("orange"), context: context, style_profile: style_profile)

    expect(preferred.score).to be > disliked.score
    expect(preferred.score_breakdown.keys).to contain_exactly("color", "occasion", "weather", "preference", "style", "repeat")
  end

  it "penalizes combinations containing recently worn items" do
    combination = combination_with("white")
    recent = combination.items.values.index_with { Time.current.to_date.iso8601 }
    personalized = described_class.call(
      combination: combination,
      context: context,
      style_profile: style_profile,
      personalization: { "last_worn_by_item_id" => recent.transform_keys { |item| item.id.to_s } }
    )
    fresh = described_class.call(combination: combination, context: context, style_profile: style_profile)

    expect(personalized.score_breakdown.fetch("repeat")).to eq(20.0)
    expect(personalized.score).to be < fresh.score
  end
end
