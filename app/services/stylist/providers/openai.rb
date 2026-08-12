require "json"
require "net/http"
require "timeout"

module Stylist
  module Providers
    class Openai
      ENDPOINT = "https://api.openai.com/v1/responses".freeze
      DEFAULT_MODEL = ClothingAnalysis::Providers::Openai::DEFAULT_MODEL
      RESULT_SCHEMA = {
        type: "object",
        additionalProperties: false,
        required: [ "rankings" ],
        properties: {
          rankings: {
            type: "array",
            minItems: 1,
            maxItems: 3,
            items: {
              type: "object",
              additionalProperties: false,
              required: %w[candidate_id explanation],
              properties: {
                candidate_id: { type: "integer" },
                explanation: { type: "string" }
              }
            }
          }
        }
      }.freeze

      def initialize(
        api_key: AppConfig.fetch(:openai_api_key),
        model: AppConfig.fetch(:openai_stylist_model, default: DEFAULT_MODEL),
        endpoint: AppConfig.fetch(:openai_api_endpoint, default: ENDPOINT)
      )
        @api_key = api_key
        @model = model
        @endpoint = URI(endpoint)
      end

      def call(prompt:, context:, candidates:)
        raise ConfigurationError, "OpenAI API key is not configured" if @api_key.blank?

        response = perform_request(request_payload(prompt, context, candidates))
        response_body = JSON.parse(response.body)
        result = JSON.parse(extract_output_text(response_body))

        {
          rankings: result.fetch("rankings"),
          metadata: {
            "provider" => "openai",
            "model" => @model,
            "response_id" => response_body["id"],
            "usage" => response_body["usage"]
          }.compact
        }
      rescue JSON::ParserError, KeyError
        raise InvalidRankingError, "Stylist provider returned invalid JSON"
      end

      private

      def request_payload(prompt, context, candidates)
        {
          model: @model,
          store: false,
          input: [
            {
              role: "system",
              content: "Rank only the supplied valid outfit candidates. Return the best distinct options with concise, user-facing explanations."
            },
            {
              role: "user",
              content: JSON.generate(prompt: prompt, context: context, candidates: candidates)
            }
          ],
          text: {
            format: {
              type: "json_schema",
              name: "outfit_rankings",
              strict: true,
              schema: RESULT_SCHEMA
            }
          },
          max_output_tokens: 600
        }
      end

      def perform_request(payload)
        request = Net::HTTP::Post.new(@endpoint)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(payload)

        response = Net::HTTP.start(
          @endpoint.host,
          @endpoint.port,
          use_ssl: @endpoint.scheme == "https",
          open_timeout: 10,
          read_timeout: 60
        ) { |http| http.request(request) }

        return response if response.is_a?(Net::HTTPSuccess)

        raise ProviderError, "Stylist provider request failed with status #{response.code}"
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => error
        raise ProviderError, "Stylist provider request failed: #{error.class.name}"
      end

      def extract_output_text(response_body)
        message = Array(response_body["output"]).find { |output| output["type"] == "message" }
        content = Array(message&.fetch("content", nil)).find { |item| item["type"] == "output_text" }
        content&.fetch("text", nil).presence || raise(InvalidRankingError, "Stylist provider returned no output")
      end
    end
  end
end
