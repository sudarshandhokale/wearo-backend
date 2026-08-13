module Routines
  class ParsePrompt
    DAY_PATTERNS = {
      1 => /\b(mon|monday)s?\b/i, 2 => /\b(tue|tues|tuesday)s?\b/i,
      3 => /\b(wed|wednesday)s?\b/i, 4 => /\b(thu|thur|thurs|thursday)s?\b/i,
      5 => /\b(fri|friday)s?\b/i, 6 => /\b(sat|saturday)s?\b/i,
      7 => /\b(sun|sunday)s?\b/i
    }.freeze
    ROUTINES = {
      "school_dropoff" => /\b(kita|daycare|school)\s*(?:drop[ -]?off|run)?\b/i,
      "workout" => /\b(gym|workout|training|exercise)\b/i,
      "walking" => /\b(walk|walking)\b/i,
      "work" => /\b(work|office)\b/i,
      "religious" => /\b(church|temple|mosque|religious service|puja|pooja)\b/i,
      "social" => /\b(dinner|friends|social|date night)\b/i
    }.freeze
    USAGE_BY_TYPE = {
      "school_dropoff" => "everyday", "workout" => "workout", "walking" => "walking",
      "work" => "work", "religious" => "special_occasion", "social" => "social"
    }.freeze

    class << self
      def call(prompt)
        prompt = Ai::Guardrails.user_prompt!(prompt.to_s)
        clauses = prompt.split(
          /(?<=[.;])|\s*,\s*|\s+and\s+(?=(?:I\s+)?(?:go|walk|work|drop|visit|gym|office|kita|daycare|school|workout|training|exercise|church|temple|mosque|dinner))/i
        )
        drafts = clauses.filter_map { |clause| draft_for(clause.squish, prompt) }
        raise InvalidPromptError if drafts.empty?

        drafts.uniq { |draft| [ draft[:routine_type], draft[:days_of_week], draft[:local_time] ] }
      rescue Ai::GuardrailViolationError
        raise InvalidPromptError
      end

      private

      def draft_for(clause, full_prompt)
        routine_type = ROUTINES.find { |_type, pattern| clause.match?(pattern) }&.first
        return if routine_type.blank?

        local_time = time_for(clause, routine_type)
        {
          name: I18n.t("routines.names.#{routine_type}"),
          routine_type: routine_type,
          days_of_week: days_for(clause, full_prompt),
          local_time: local_time,
          usage: USAGE_BY_TYPE.fetch(routine_type),
          city_mode: "profile",
          outfit_strategy: routine_type == "school_dropoff" ? "combine_with_next" : "separate",
          recommendation_lead_minutes: RecommendationTiming.lead_minutes(local_time),
          reminder_enabled: false,
          active: true
        }
      end

      def days_for(clause, _full_prompt)
        return [ 1, 2, 3, 4, 5 ] if clause.match?(/\b(weekdays|monday\s+(?:to|through|-)\s+friday)\b/i)
        return [ 1, 3, 5 ] if clause.match?(/\b(alternate|alternating)\s+days?\b/i)

        days = DAY_PATTERNS.filter_map { |day, pattern| day if clause.match?(pattern) }
        days.presence || [ 1, 2, 3, 4, 5 ]
      end

      def time_for(clause, routine_type)
        match = clause.match(/\b([01]?\d|2[0-3])(?::([0-5]\d))?\s*(am|pm)?\b/i)
        return default_time(routine_type) unless match

        hour = match[1].to_i
        hour = (hour % 12) + 12 if match[3]&.downcase == "pm"
        hour %= 12 if match[3]&.downcase == "am"
        format("%02d:%02d", hour, match[2].to_i)
      end

      def default_time(type)
        { "school_dropoff" => "07:30", "walking" => "07:00", "work" => "08:30", "workout" => "18:00" }.fetch(type, "09:00")
      end
    end

    class InvalidPromptError < StandardError; end
  end
end
