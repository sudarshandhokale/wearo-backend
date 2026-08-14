require "rails_helper"

RSpec.describe AiEvaluations::OutfitRecommendationRunner do
  describe ".call" do
    it "runs configured scenarios without persisting evaluation records" do
      expect {
        summary = described_class.call

        expect(summary.total_count).to eq(3)
        expect(summary).to be_passed
      }.not_to change(User, :count)
    end

    it "reports failed expectation checks" do
      scenario_path = Rails.root.join("tmp/ai_eval_failure.yml")
      File.write(
        scenario_path,
        [
          {
            "id" => "blocked_color_failure",
            "name" => "Blocked color failure",
            "prompt" => "Dinner outfit",
            "profile" => { "disliked_colors" => [ "orange" ] },
            "context" => {
              "occasion" => "dinner",
              "formality" => "smart_casual",
              "activity" => "social",
              "season" => "summer",
              "usage" => "social"
            },
            "wardrobe" => [
              {
                "name" => "Orange Shirt",
                "category" => "top",
                "subcategory" => "shirt",
                "primary_color" => "orange",
                "season_tags" => [ "summer" ],
                "occasion_tags" => [ "dinner" ],
                "style_tags" => [ "classic" ],
                "usage_tags" => [ "social" ],
                "formality_score" => 5
              },
              {
                "name" => "Black Trousers",
                "category" => "bottom",
                "subcategory" => "trousers",
                "primary_color" => "black",
                "season_tags" => [ "summer" ],
                "occasion_tags" => [ "dinner" ],
                "style_tags" => [ "classic" ],
                "usage_tags" => [ "social" ],
                "formality_score" => 5
              }
            ],
            "expectations" => {
              "min_recommendations" => 1,
              "avoid_colors" => [ "orange" ]
            }
          }
        ].to_yaml
      )

      summary = described_class.call(path: scenario_path)

      expect(summary).not_to be_passed
      expect(summary.results.first.failed_checks.map(&:name)).to include("avoid_colors")
    ensure
      FileUtils.rm_f(scenario_path)
    end
  end
end
