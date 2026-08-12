module StylingPlans
  class PromptInterpreter
    VACATION_PATTERN = /\b(vacation|holiday|trip|travel|traveling|travelling|pack|packing|itinerary)\b/i
    DURATION_PATTERNS = [
      /\bfor\s+(\d{1,2})\s+days?\b/i,
      /\bnext\s+(\d{1,2})\s+days?\b/i,
      /\b(\d{1,2})[- ]day\b/i
    ].freeze

    Result = Data.define(:plan_type, :city, :start_date, :end_date)

    class << self
      def call(user:, attributes:)
        values = attributes.to_h.symbolize_keys
        prompt = values[:prompt].to_s
        plan_type = values[:plan_type].presence || inferred_plan_type(prompt)
        start_date = parse_date(values[:start_date]) || inferred_start_date(user, prompt, plan_type)
        end_date = parse_date(values[:end_date]) || start_date + inferred_duration(prompt) - 1

        Result.new(
          plan_type: plan_type,
          city: values[:city].to_s.strip.presence || extracted_city(prompt, user),
          start_date: start_date,
          end_date: end_date
        )
      end

      private

      def inferred_plan_type(prompt)
        prompt.match?(VACATION_PATTERN) ? "vacation" : "week"
      end

      def inferred_start_date(user, prompt, plan_type)
        today = Time.current.in_time_zone(user.timezone).to_date
        return today if prompt.match?(/\bnext\s+\d{1,2}\s+days?\b/i)
        return today if prompt.match?(/\b(this week|starting today|from today)\b/i)
        return today + 1.day if prompt.match?(/\b(starting tomorrow|from tomorrow|tomorrow)\b/i)
        return today.next_occurring(:monday) if prompt.match?(/\bnext week\b/i) || plan_type == "week"

        today + 1.day
      end

      def inferred_duration(prompt)
        value = DURATION_PATTERNS.filter_map { |pattern| prompt.match(pattern)&.[](1) }.first
        Integer(value, exception: false) || 7
      end

      def extracted_city(prompt, user)
        return user.preferred_city if prompt.blank?

        Stylist::ExtractContext.call(prompt, timezone: user.timezone).city || user.preferred_city
      end

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue Date::Error
        raise InvalidDateRangeError
      end
    end
  end
end
