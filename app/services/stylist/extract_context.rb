module Stylist
  class ExtractContext
    OCCASION_RULES = {
      "work" => /\b(work|office|business|meeting|interview)\b/i,
      "dinner" => /\b(dinner|restaurant|supper)\b/i,
      "date_night" => /\b(date|romantic)\b/i,
      "party" => /\b(party|club|celebration|birthday)\b/i,
      "concert" => /\b(concert|live music|music gig|music festival|band performance)\b/i,
      "wedding" => /\b(wedding|reception|sangeet|mehndi|haldi)\b/i,
      "festival" => /\b(festival|diwali|holi|navratri|eid|onam|pongal|baisakhi|durga puja)\b/i,
      "religious_ceremony" => /\b(puja|pooja|temple|religious ceremony)\b/i,
      "family_function" => /\b(family function|family gathering)\b/i,
      "workout" => /\b(workout|gym|training|run|running|exercise)\b/i,
      "outdoor" => /\b(picnic|hike|hiking|outdoor|park|camping)\b/i,
      "travel" => /\b(travel|flight|airport|road trip)\b/i
    }.freeze
    FORMALITY_RULES = {
      "formal" => /\b(formal|wedding|reception|sangeet|mehndi|haldi|gala|black tie|ceremony)\b/i,
      "smart_casual" => /\b(smart casual|work|office|business|meeting|interview|dinner|restaurant|date)\b/i,
      "casual" => /\b(casual|picnic|friends|weekend|workout|gym|hike|travel)\b/i
    }.freeze
    ACTIVITY_RULES = {
      "professional" => /\b(work|office|business|meeting|interview)\b/i,
      "social" => /\b(dinner|date|friends|party|restaurant|celebration)\b/i,
      "music_event" => /\b(concert|live music|music gig|music festival|band performance)\b/i,
      "walking" => /\b(walk|walking|sightseeing)\b/i,
      "active" => /\b(workout|gym|run|running|hike|hiking|exercise)\b/i,
      "outdoor" => /\b(picnic|outdoor|park|camping)\b/i,
      "travel" => /\b(travel|flight|airport|road trip)\b/i
    }.freeze
    SEASON_RULES = {
      "spring" => /\bspring\b/i,
      "summer" => /\b(summer|hot|warm)\b/i,
      "fall" => /\b(fall|autumn)\b/i,
      "winter" => /\b(winter|cold|snow)\b/i
    }.freeze
    USAGE_RULES = {
      "special_occasion" => /\b(wedding|reception|gala|black tie|sangeet|mehndi|haldi|religious ceremony)\b/i,
      "event" => /\b(concert|festival|party|club|celebration)\b/i,
      "work" => /\b(work|office|business|meeting|interview)\b/i,
      "travel" => /\b(travel|trip|vacation|holiday|flight|airport|road trip)\b/i,
      "workout" => /\b(workout|gym|training|run|running|exercise)\b/i,
      "walking" => /\b(walk|walking|sightseeing)\b/i,
      "outdoor" => /\b(picnic|hike|hiking|outdoor|park|camping)\b/i,
      "social" => /\b(dinner|date|friends|restaurant|social)\b/i,
      "home" => /\b(home|indoors|lounging|loungewear)\b/i,
      "errands" => /\b(errand|errands|shopping|groceries)\b/i,
      "everyday" => /\b(daily|everyday|casual|regular day)\b/i
    }.freeze
    LOCATION_WORD = "[[:alpha:]][[:alpha:]'.-]*"
    LOCATION_END = "(?=\\s+(?:on|for|this|next|today|tomorrow|tonight|with|during|after|before)\\b|[,.!?]|\\z)"
    LOCATION_PATTERNS = [
      /\b(?:going|traveling|travelling|flying|heading)\s+to\s+(#{LOCATION_WORD}(?:\s+#{LOCATION_WORD}){0,3}?)#{LOCATION_END}/i,
      /\b(?:trip|vacation|holiday)\s+(?:in|to)\s+(#{LOCATION_WORD}(?:\s+#{LOCATION_WORD}){0,3}?)#{LOCATION_END}/i,
      /\b(?:destination|city|location)\s+(?:is|:)\s*(#{LOCATION_WORD}(?:\s+#{LOCATION_WORD}){0,3}?)#{LOCATION_END}/i,
      /\bpack(?:ing)?\s+for\s+(#{LOCATION_WORD}(?:\s+#{LOCATION_WORD}){0,3}?)#{LOCATION_END}/i,
      /\b(?:in|near|around|visiting|visit)\s+(#{LOCATION_WORD}(?:\s+#{LOCATION_WORD}){0,3}?)#{LOCATION_END}/i
    ].freeze
    NON_LOCATION_WORDS = %w[
      a an the work office dinner restaurant party concert wedding festival gym park
      spring summer fall autumn winter cold hot warm rain rainy snow snowy
    ].freeze
    MONTH_LOOKUP = Date::MONTHNAMES.compact.each_with_index.to_h { |name, index| [ name.downcase, index + 1 ] }
      .merge(Date::ABBR_MONTHNAMES.compact.each_with_index.to_h { |name, index| [ name.downcase, index + 1 ] }).freeze
    MONTH_PATTERN = MONTH_LOOKUP.keys.sort_by { |name| -name.length }.join("|")
    WEEKDAY_PATTERN = Date::DAYNAMES.join("|")

    class << self
      def call(prompt, timezone:, now: Time.current)
        raise InvalidPromptError if prompt.blank? || prompt.length > 1_000

        local_now = now.in_time_zone(timezone.presence || "UTC")
        attributes = {
          "occasion" => match_rule(prompt, OCCASION_RULES, "casual"),
          "formality" => match_rule(prompt, FORMALITY_RULES, "casual"),
          "activity" => match_rule(prompt, ACTIVITY_RULES, "social"),
          "season" => match_rule(prompt, SEASON_RULES, nil),
          "usage" => match_rule(prompt, USAGE_RULES, "everyday")
        }.compact

        ExtractedContext.new(
          attributes: attributes,
          recommended_for: extract_recommended_for(prompt, local_now),
          city: extract_city(prompt)
        )
      end

      private

      def match_rule(prompt, rules, default)
        rules.find { |_value, pattern| prompt.match?(pattern) }&.first || default
      end

      def extract_recommended_for(prompt, local_now)
        explicit_date = extract_explicit_date(prompt, local_now.to_date)
        return local_time_for(explicit_date, prompt, local_now) if explicit_date
        return local_time_for(local_now.to_date, prompt, local_now, default_hour: 19) if prompt.match?(/\btonight\b/i)
        return local_time_for(local_now.to_date, prompt, local_now, default_hour: local_now.hour, default_minute: local_now.min) if prompt.match?(/\btoday\b/i)
        return local_time_for(local_now.to_date + 1.day, prompt, local_now) if prompt.match?(/\btomorrow\b/i)

        weekday_match = prompt.match(/\b(next\s+)?(#{WEEKDAY_PATTERN})\b/i)
        weekday = weekday_match&.[](2)&.downcase&.capitalize
        return if weekday.blank?

        days_ahead = (Date::DAYNAMES.index(weekday) - local_now.wday) % 7
        days_ahead = 7 if weekday_match[1].present? && days_ahead.zero?
        local_time_for(local_now.to_date + days_ahead.days, prompt, local_now)
      end

      def extract_explicit_date(prompt, today)
        if (match = prompt.match(/\b(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})\b/))
          return validated_date(match[1], match[2], match[3], today, explicit_year: true)
        end
        if (match = prompt.match(/\b(#{MONTH_PATTERN})\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?\b/i))
          return named_date(match[1], match[2], match[3], today)
        end
        if (match = prompt.match(/\b(\d{1,2})(?:st|nd|rd|th)?\s+(#{MONTH_PATTERN})(?:,?\s+(\d{4}))?\b/i))
          return named_date(match[2], match[1], match[3], today)
        end
        if (match = prompt.match(/\b(\d{1,2})(?:st|nd|rd|th)?\s+of\s+(#{MONTH_PATTERN})(?:,?\s+(\d{4}))?\b/i))
          return named_date(match[2], match[1], match[3], today)
        end
        return unless (match = prompt.match(/\b(\d{1,2})[\/.](\d{1,2})[\/.](\d{4})\b/))

        day = match[1].to_i
        month = match[2].to_i
        raise InvalidPromptError if day <= 12 && month <= 12

        validated_date(match[3], month, day, today, explicit_year: true)
      end

      def named_date(month_name, day, year, today)
        month = MONTH_LOOKUP.fetch(month_name.downcase)
        candidate = validated_date(year || today.year, month, day, today, explicit_year: year.present?)
        year.present? || candidate >= today ? candidate : validated_date(today.year + 1, month, day, today, explicit_year: false)
      end

      def validated_date(year, month, day, today, explicit_year:)
        date = Date.new(year.to_i, month.to_i, day.to_i)
        raise InvalidPromptError if explicit_year && date < today

        date
      rescue Date::Error
        raise InvalidPromptError
      end

      def local_time_for(date, prompt, local_now, default_hour: 12, default_minute: 0)
        match = prompt.match(/\bat\s+([01]?\d|2[0-3])(?::([0-5]\d))?\s*(am|pm)?\b/i)
        hour = match ? match[1].to_i : default_hour
        minute = match ? match[2].to_i : default_minute
        hour = (hour % 12) + 12 if match&.[](3)&.downcase == "pm"
        hour %= 12 if match&.[](3)&.downcase == "am"
        local_now.change(year: date.year, month: date.month, day: date.day, hour: hour, min: minute, sec: 0)
      end

      def extract_city(prompt)
        candidate = LOCATION_PATTERNS.filter_map { |pattern| prompt.match(pattern)&.[](1) }.first
        return if candidate.blank?

        words = candidate.downcase.scan(/[[:alpha:]]+/)
        return if words.empty? || words.any? { |word| NON_LOCATION_WORDS.include?(word) }

        candidate.squish
      end
    end
  end
end
