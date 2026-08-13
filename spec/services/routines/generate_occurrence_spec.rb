require "rails_helper"

RSpec.describe Routines::GenerateOccurrence do
  it "generates and stores one deterministic routine outfit" do
    user = create(:user, preferred_city: "Berlin")
    item = create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "one_piece", subcategory: "dress", user_usage_tags: [ "work" ])
    routine = create(:styling_routine, user: user)
    occurrence = create(:routine_occurrence, user: user, styling_routine: routine)
    allow(ExternalContext::Fetch).to receive(:call).and_return(
      ExternalContext::Result.new(city: "Berlin", country_code: "DE", weather: [ { "condition" => "clear" } ])
    )

    described_class.call(occurrence)

    expect(occurrence.reload).to be_generated
    expect(occurrence.outfit.clothing_item_ids).to eq([ item.id ])
    expect(occurrence.context).to include("usage" => "work", "routine_name" => "Office")
    expect(occurrence.outfit.recommendation_request).to be_nil
  end

  it "shares the following routine outfit when combine-with-next is enabled" do
    user = create(:user)
    create(:clothing_item, user: user, wardrobe: user.wardrobe, category: "one_piece", subcategory: "dress", user_usage_tags: [ "work" ])
    dropoff = create(:styling_routine, user: user, routine_type: "school_dropoff", usage: "everyday", outfit_strategy: "combine_with_next")
    office = create(:styling_routine, user: user)
    first = create(:routine_occurrence, user: user, styling_routine: dropoff, scheduled_for: 1.day.from_now)
    second = create(:routine_occurrence, user: user, styling_routine: office, scheduled_for: first.scheduled_for + 1.hour)
    allow(ExternalContext::Fetch).to receive(:call).and_return(ExternalContext::Result.new(city: nil, country_code: "US", weather: []))

    described_class.call(first)

    expect(first.reload).to be_generated
    expect(second.reload).to be_generated
    expect(second.outfit_id).to eq(first.outfit_id)
    expect(second.context).to include("combined" => true, "routine_name" => "Office")
  end
end
