module Ai
  class Guardrails
    CONTROL_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/
    HTML = /<\/?[a-z][^>]*>/i
    MARKDOWN_LINK = /!?\[[^\]]*\]\([^)]+\)/
    URL = %r{https?://}i
    INJECTION_PATTERNS = [
      /ignore\s+(all\s+)?(previous|prior)\s+instructions?/i,
      /(?:reveal|repeat|show)\s+(?:the\s+)?(?:system|developer)\s+(?:prompt|message|instructions?)/i,
      /(?:system|developer)\s+(?:prompt|message|instructions?)\s*:/i,
      /you\s+are\s+now\s+(?:in\s+)?developer\s+mode/i
    ].freeze
    TOKEN = /\A[a-z0-9]+(?:_[a-z0-9]+)*\z/
    INJECTION_TOKEN = /(?:ignore_.*instructions?|reveal_.*(?:system|developer)_prompt|system_prompt|developer_mode)/

    class << self
      def user_prompt!(value, max_length: 1_000)
        plain_text!(value, max_length: max_length, inspect_injection: false)
      end

      def model_text!(value, max_length:, allow_nil: false)
        return if value.nil? && allow_nil

        plain_text!(value, max_length: max_length, inspect_injection: true)
      end

      def token!(value, max_length: 50, allow_nil: false)
        return if value.nil? && allow_nil
        safe = value.is_a?(String) && value.length <= max_length && value.match?(TOKEN) && !value.match?(INJECTION_TOKEN)
        raise GuardrailViolationError unless safe

        value
      end

      def token_list!(value, max_items: 12, max_length: 50)
        raise GuardrailViolationError unless value.is_a?(Array) && value.length <= max_items

        value.each { |item| token!(item, max_length: max_length) }
        value
      end

      private

      def plain_text!(value, max_length:, inspect_injection:)
        raise GuardrailViolationError unless value.is_a?(String)

        normalized = value.squish
        unsafe = normalized.blank? || normalized.length > max_length ||
                 normalized.match?(CONTROL_CHARACTERS) || normalized.match?(HTML) ||
                 normalized.match?(MARKDOWN_LINK) || normalized.match?(URL)
        unsafe ||= INJECTION_PATTERNS.any? { |pattern| normalized.match?(pattern) } if inspect_injection
        raise GuardrailViolationError if unsafe

        normalized
      end
    end
  end
end
