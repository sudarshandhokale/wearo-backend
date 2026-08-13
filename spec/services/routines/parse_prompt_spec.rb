require "rails_helper"

RSpec.describe Routines::ParsePrompt do
  it "extracts office, drop-off, walking, and gym drafts for confirmation" do
    drafts = described_class.call(
      "Office weekdays at 8:30. Kita drop-off weekdays at 7:30. Walking Monday Wednesday Friday at 7am. Gym Tuesday Thursday at 6pm."
    )

    expect(drafts.pluck(:routine_type)).to contain_exactly("work", "school_dropoff", "walking", "workout")
    expect(drafts.find { |item| item[:routine_type] == "walking" }).to include(
      days_of_week: [ 1, 3, 5 ], local_time: "07:00", usage: "walking"
    )
    expect(drafts.find { |item| item[:routine_type] == "workout" }).to include(
      days_of_week: [ 2, 4 ], local_time: "18:00", usage: "workout", recommendation_lead_minutes: 60
    )
    expect(drafts.find { |item| item[:routine_type] == "work" })
      .to include(local_time: "08:30", recommendation_lead_minutes: 750)
    expect(drafts.find { |item| item[:routine_type] == "school_dropoff" })
      .to include(outfit_strategy: "combine_with_next")
  end

  it "rejects text without a recognizable recurring activity" do
    expect { described_class.call("What should I wear?") }.to raise_error(described_class::InvalidPromptError)
  end
end
