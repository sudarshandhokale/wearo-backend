require "rails_helper"

RSpec.describe StylingPlans::PromptInterpreter do
  it "infers a vacation destination, next-week dates, and duration from a prompt" do
    user = create(:user, preferred_city: "Hamburg", timezone: "Europe/Berlin")
    start_on = Time.current.in_time_zone(user.timezone).to_date.next_occurring(:monday)

    result = described_class.call(
      user: user,
      attributes: { prompt: "Pack for Paris next week for 5 days" }
    )

    expect(result).to have_attributes(
      plan_type: "vacation",
      city: "Paris",
      start_date: start_on,
      end_date: start_on + 4
    )
  end

  it "keeps explicit form values authoritative" do
    user = create(:user, preferred_city: "Hamburg")

    result = described_class.call(
      user: user,
      attributes: {
        plan_type: "week",
        city: "Berlin",
        start_date: "2026-08-20",
        end_date: "2026-08-22",
        prompt: "Pack for Paris next week"
      }
    )

    expect(result).to have_attributes(
      plan_type: "week",
      city: "Berlin",
      start_date: Date.new(2026, 8, 20),
      end_date: Date.new(2026, 8, 22)
    )
  end

  it "supports a rolling next-days plan" do
    user = create(:user, timezone: "Europe/Berlin")
    today = Time.current.in_time_zone(user.timezone).to_date

    result = described_class.call(user: user, attributes: { prompt: "Plan outfits for the next 3 days" })

    expect(result).to have_attributes(plan_type: "week", start_date: today, end_date: today + 2)
  end
end
