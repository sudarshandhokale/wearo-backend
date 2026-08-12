module Ai
  class UsageTracker
    DEFAULT_DAILY_TOKEN_LIMIT = 50_000
    DEFAULT_DAILY_REQUEST_LIMIT = 100

    class << self
      def daily_summary(user)
        scope = daily_scope(user)
        token_limit = configured_limit(:ai_daily_token_limit, DEFAULT_DAILY_TOKEN_LIMIT)
        request_limit = configured_limit(:ai_daily_request_limit, DEFAULT_DAILY_REQUEST_LIMIT)
        tokens_used = scope.succeeded.sum(:total_tokens)
        tokens_reserved = scope.pending.sum(:reserved_tokens)
        requests_used = scope.count

        {
          date: Time.current.in_time_zone(user.timezone).to_date.iso8601,
          tokens_used: tokens_used,
          tokens_reserved: tokens_reserved,
          token_limit: token_limit,
          tokens_remaining: [ token_limit - tokens_used - tokens_reserved, 0 ].max,
          requests_used: requests_used,
          request_limit: request_limit,
          requests_remaining: [ request_limit - requests_used, 0 ].max
        }
      end

      def start!(user:, operation:, trackable:, reserved_tokens:)
        user.with_lock do
          scope = daily_scope(user)
          enforce_request_limit!(scope)
          enforce_token_limit!(scope, reserved_tokens)

          user.ai_requests.create!(
            operation: operation,
            trackable: trackable,
            reserved_tokens: reserved_tokens
          )
        end
      end

      def succeed!(ai_request, metadata)
        usage = metadata.fetch("usage", {}).to_h.stringify_keys
        input_tokens = non_negative_integer(usage["input_tokens"])
        output_tokens = non_negative_integer(usage["output_tokens"])

        ai_request.update!(
          status: :succeeded,
          provider: metadata["provider"],
          model: metadata["model"],
          response_id: metadata["response_id"],
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          total_tokens: non_negative_integer(usage["total_tokens"], fallback: input_tokens + output_tokens),
          attempt_count: non_negative_integer(metadata["attempt_count"], fallback: 1),
          reserved_tokens: 0,
          completed_at: Time.current
        )
      end

      def fail!(ai_request, error, metadata: {})
        return if ai_request.blank? || !ai_request.pending?

        ai_request.update!(
          status: :failed,
          provider: metadata["provider"],
          model: metadata["model"],
          attempt_count: non_negative_integer(metadata["attempt_count"], fallback: error.try(:attempt_count).to_i),
          failure_code: error.class.name.demodulize.underscore,
          reserved_tokens: 0,
          completed_at: Time.current
        )
      end

      private

      def enforce_request_limit!(scope)
        raise UsageLimitExceededError if scope.count >= configured_limit(:ai_daily_request_limit, DEFAULT_DAILY_REQUEST_LIMIT)
      end

      def enforce_token_limit!(scope, requested_tokens)
        consumed = scope.succeeded.sum(:total_tokens)
        reserved = scope.pending.sum(:reserved_tokens)
        limit = configured_limit(:ai_daily_token_limit, DEFAULT_DAILY_TOKEN_LIMIT)
        raise UsageLimitExceededError if consumed + reserved + requested_tokens > limit
      end

      def configured_limit(key, default)
        value = Integer(AppConfig.fetch(key, default: default), exception: false) || default
        value.clamp(1, 10_000_000)
      end

      def daily_scope(user)
        local_day = Time.current.in_time_zone(user.timezone).all_day
        user.ai_requests.where(created_at: local_day)
      end

      def non_negative_integer(value, fallback: 0)
        parsed = Integer(value, exception: false)
        parsed.nil? || parsed.negative? ? fallback : parsed
      end
    end
  end
end
