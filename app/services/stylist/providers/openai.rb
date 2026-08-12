require "json"
require "digest"

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
        endpoint: AppConfig.fetch(:openai_api_endpoint, default: ENDPOINT),
        http_client: Ai::HttpClient.new
      )
        @api_key = api_key
        @model = model
        @endpoint = URI(endpoint)
        @http_client = http_client
      end

      def call(prompt:, context:, candidates:, user_id:)
        raise ConfigurationError, "OpenAI API key is not configured" if @api_key.blank?

        http_result = perform_request(request_payload(prompt, context, candidates, user_id))
        response = http_result.response
        response_body = JSON.parse(response.body)
        result = JSON.parse(extract_output_text(response_body))

        {
          rankings: result.fetch("rankings"),
          metadata: {
            "provider" => "openai",
            "model" => @model,
            "response_id" => response_body["id"],
            "usage" => response_body["usage"],
            "attempt_count" => http_result.attempt_count
          }.compact
        }
      rescue JSON::ParserError, KeyError
        raise InvalidRankingError, "Stylist provider returned invalid JSON"
      end

      private

      def request_payload(prompt, context, candidates, user_id)
        {
          model: @model,
          store: false,
          safety_identifier: safety_identifier(user_id),
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
        @http_client.post(
          endpoint: @endpoint,
          headers: { "Authorization" => "Bearer #{@api_key}", "Content-Type" => "application/json" },
          body: JSON.generate(payload)
        )
      rescue Ai::HttpError => error
        provider_error = ProviderError.new("Stylist provider request failed")
        provider_error.define_singleton_method(:attempt_count) { error.attempt_count }
        raise provider_error
      end

      def safety_identifier(user_id)
        secret = Rails.application.secret_key_base
        Digest::SHA256.hexdigest("wearo-stylist:#{user_id}:#{secret}")
      end

      def extract_output_text(response_body)
        message = Array(response_body["output"]).find { |output| output["type"] == "message" }
        content = Array(message&.fetch("content", nil)).find { |item| item["type"] == "output_text" }
        content&.fetch("text", nil).presence || raise(InvalidRankingError, "Stylist provider returned no output")
      end
    end
  end
end
