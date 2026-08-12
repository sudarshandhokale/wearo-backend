require "net/http"
require "timeout"

module Ai
  class HttpClient
    RETRYABLE_STATUSES = [ 429, 500, 502, 503, 504 ].freeze
    RETRYABLE_ERRORS = [ Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET ].freeze
    MAX_ATTEMPTS = 3

    Result = Data.define(:response, :attempt_count)

    def initialize(sleeper: Kernel.method(:sleep))
      @sleeper = sleeper
    end

    def post(endpoint:, headers:, body:)
      validate_endpoint!(endpoint)
      attempts = 0

      loop do
        attempts += 1
        response = perform_post(endpoint, headers, body)
        return Result.new(response: response, attempt_count: attempts) if response.is_a?(Net::HTTPSuccess)

        if RETRYABLE_STATUSES.include?(response.code.to_i) && attempts < MAX_ATTEMPTS
          wait_before_retry(attempts)
          next
        end

        raise HttpError.new(status: response.code.to_i, attempt_count: attempts)
      rescue *RETRYABLE_ERRORS
        if attempts < MAX_ATTEMPTS
          wait_before_retry(attempts)
          retry
        end

        raise HttpError.new(attempt_count: attempts)
      end
    end

    private

    def validate_endpoint!(endpoint)
      return if endpoint.is_a?(URI::HTTPS) && endpoint.host.present?

      raise HttpError.new(attempt_count: 0)
    end

    def perform_post(endpoint, headers, body)
      request = Net::HTTP::Post.new(endpoint)
      headers.each { |key, value| request[key] = value }
      request.body = body

      Net::HTTP.start(
        endpoint.host,
        endpoint.port,
        use_ssl: true,
        open_timeout: 10,
        read_timeout: 60
      ) { |http| http.request(request) }
    end

    def wait_before_retry(attempts)
      @sleeper.call(0.25 * (2**(attempts - 1)))
    end
  end
end
