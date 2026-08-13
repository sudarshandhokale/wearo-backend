require "rails_helper"

RSpec.describe Routines::ScheduleOccurrences do
  it "creates one timezone-aware occurrence and remains idempotent" do
    user = create(:user, timezone: "Europe/Berlin")
    routine = create(:styling_routine, user: user, days_of_week: [ 1 ], local_time: "08:30", recommendation_lead_minutes: 720)
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 17, 0, 0)

    expect do
      described_class.call(now: now, horizon: 24.hours)
      described_class.call(now: now, horizon: 24.hours)
    end.to change(routine.occurrences, :count).by(1)

    occurrence = routine.occurrences.first
    expect(occurrence.scheduled_for.in_time_zone(user.timezone).strftime("%F %H:%M")).to eq("2026-08-17 08:30")
    expect(GenerateRoutineOccurrenceJob).to have_been_enqueued.with(occurrence.id)
  end

  it "does not separately queue the next occurrence in a combined routine" do
    now = Time.find_zone!("Europe/Berlin").local(2026, 8, 17, 0, 0)
    user = create(:user, timezone: "Europe/Berlin")
    other_user = create(:user, timezone: "Europe/Berlin")
    dropoff = create(:styling_routine, user: user, days_of_week: [ 1 ], local_time: "07:30",
                                                outfit_strategy: "combine_with_next")
    office = create(:styling_routine, user: user, days_of_week: [ 1 ], local_time: "08:30")
    create(:styling_routine, user: other_user, days_of_week: [ 1 ], local_time: "08:00")

    described_class.call(now: now, horizon: 24.hours)

    expect(dropoff.occurrences.first).to be_queued
    expect(office.occurrences.first).to be_scheduled
    expect(other_user.routine_occurrences.first).to be_queued
  end
end
