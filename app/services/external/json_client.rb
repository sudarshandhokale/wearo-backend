require "json"
require "net/http"
require "timeout"

module External
  class JsonClient
    RETRYABLE_STATUSES = [ 429, 500, 502, 503, 504 ].freeze
    RETRYABLE_ERRORS = [ Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET ].freeze
    MAX_ATTEMPTS = 3

    def initialize(sleeper: Kernel.method(:sleep))
      @sleeper = sleeper
    end

    def get(endpoint:, headers: {})
      validate_endpoint!(endpoint)
      attempts = 0

      loop do
        attempts += 1
        response = perform_get(endpoint, headers)
        return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

        if RETRYABLE_STATUSES.include?(response.code.to_i)
          retry_request!(attempts)
          next
        end
        raise ProviderError
      rescue *RETRYABLE_ERRORS, JSON::ParserError
        retry_request!(attempts)
        retry
      end
    end

    private

    def validate_endpoint!(endpoint)
      raise InvalidRequestError unless endpoint.is_a?(URI::HTTPS) && endpoint.host.present?
    end

    def perform_get(endpoint, headers)
      request = Net::HTTP::Get.new(endpoint)
      headers.each { |key, value| request[key] = value }
      Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
    end

    def retry_request!(attempts)
      raise ProviderError if attempts >= MAX_ATTEMPTS

      @sleeper.call(0.25 * (2**(attempts - 1)))
    end
  end
end
