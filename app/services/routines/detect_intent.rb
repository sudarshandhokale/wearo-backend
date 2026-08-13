module Routines
  class DetectIntent
    RECURRENCE_PATTERN = /\b(every|each|daily|weekdays?|weekends?|alternate days?|alternating days?|regularly|routine|schedule|mondays|tuesdays|wednesdays|thursdays|fridays|saturdays|sundays)\b/i
    DAY_PATTERN = /\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i
    TIME_PATTERN = /\b([01]?\d|2[0-3])(?::[0-5]\d)?\s*(?:am|pm)?\b/i

    class << self
      def recurring?(prompt)
        prompt = Ai::Guardrails.user_prompt!(prompt.to_s)
        return true if prompt.match?(RECURRENCE_PATTERN)

        prompt.scan(DAY_PATTERN).flatten.uniq.length >= 2 && prompt.match?(TIME_PATTERN)
      rescue Ai::GuardrailViolationError
        false
      end
    end
  end
end
