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

    class << self
      def call(prompt, timezone:, now: Time.current)
        raise InvalidPromptError if prompt.blank? || prompt.length > 1_000

        local_now = now.in_time_zone(timezone.presence || "UTC")
        attributes = {
          "occasion" => match_rule(prompt, OCCASION_RULES, "casual"),
          "formality" => match_rule(prompt, FORMALITY_RULES, "casual"),
          "activity" => match_rule(prompt, ACTIVITY_RULES, "social"),
          "season" => match_rule(prompt, SEASON_RULES, nil)
        }.compact

        ExtractedContext.new(
          attributes: attributes,
          recommended_for: extract_recommended_for(prompt, local_now)
        )
      end

      private

      def match_rule(prompt, rules, default)
        rules.find { |_value, pattern| prompt.match?(pattern) }&.first || default
      end

      def extract_recommended_for(prompt, local_now)
        return local_now.change(hour: 19) if prompt.match?(/\btonight\b/i)
        return local_now if prompt.match?(/\btoday\b/i)
        return (local_now + 1.day).change(hour: 12) if prompt.match?(/\btomorrow\b/i)

        weekday = Date::DAYNAMES.find { |day_name| prompt.match?(/\b#{Regexp.escape(day_name)}\b/i) }
        return if weekday.blank?

        days_ahead = (Date::DAYNAMES.index(weekday) - local_now.wday) % 7
        (local_now + days_ahead.days).change(hour: 12)
      end
    end
  end
end
