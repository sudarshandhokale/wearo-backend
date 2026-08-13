require "rails_helper"

RSpec.describe Metadata::Labels do
  it "adds localized labels to stylist context without changing raw values" do
    context = {
      "activity" => "professional",
      "occasion" => "work",
      "formality" => "smart_casual",
      "weather" => { "condition" => "rain" }
    }

    expect(described_class.context(context)).to include(
      "activity" => "professional",
      "activity_label" => "Professional",
      "occasion" => "work",
      "occasion_label" => "Work",
      "formality" => "smart_casual",
      "formality_label" => "Smart Casual",
      "weather" => include("condition" => "rain", "condition_label" => "Rain")
    )
    expect(context).not_to have_key("activity_label")
  end

  it "adds labels to suggestion control values and arrays" do
    suggestion = {
      "type" => "weather",
      "priority" => "essential",
      "action" => "bring",
      "role" => "accessory",
      "suggested_subcategories" => %w[umbrella raincoat]
    }

    expect(described_class.suggestion(suggestion)).to include(
      "type_label" => "Weather",
      "priority_label" => "Essential",
      "action_label" => "Bring",
      "role_label" => "Accessory",
      "suggested_subcategory_labels" => %w[Umbrella Raincoat]
    )
  end
end
