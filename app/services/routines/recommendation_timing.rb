module Routines
  class RecommendationTiming
    MORNING_CUTOFF_HOUR = 12
    PREVIOUS_EVENING_HOUR = 20
    SAME_DAY_LEAD_MINUTES = 60

    class << self
      def lead_minutes(local_time)
        time = Time.zone.parse(local_time.to_s)
        return SAME_DAY_LEAD_MINUTES if time.blank? || time.hour >= MORNING_CUTOFF_HOUR

        minutes_after_midnight = (time.hour * 60) + time.min
        minutes_after_midnight + ((24 - PREVIOUS_EVENING_HOUR) * 60)
      end
    end
  end
end
