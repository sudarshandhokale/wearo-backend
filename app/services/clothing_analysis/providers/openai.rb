require "base64"
require "digest"
require "json"
require "net/http"

module ClothingAnalysis
  module Providers
    class Openai
      ENDPOINT = "https://api.openai.com/v1/responses".freeze
      DEFAULT_MODEL = "gpt-5.6-luna".freeze

      def initialize(
        api_key: AppConfig.fetch(:openai_api_key),
        model: AppConfig.fetch(:openai_clothing_model, default: DEFAULT_MODEL),
        endpoint: AppConfig.fetch(:openai_api_endpoint, default: ENDPOINT)
      )
        @api_key = api_key
        @model = model
        @endpoint = URI(endpoint)
      end

      def call(image:, user_id:)
        raise ConfigurationError, "OpenAI API key is not configured" if @api_key.blank?
        raise InvalidResultError, "Clothing item image is required" unless image.attached?

        response = perform_request(request_payload(image, user_id))
        response_body = JSON.parse(response.body)

        {
          result: JSON.parse(extract_output_text(response_body)),
          metadata: {
            "provider" => "openai",
            "model" => @model,
            "response_id" => response_body["id"],
            "usage" => response_body["usage"]
          }.compact
        }
      rescue JSON::ParserError
        raise InvalidResultError, "Analysis provider returned invalid JSON"
      end

      private

      def request_payload(image, user_id)
        {
          model: @model,
          store: false,
          safety_identifier: safety_identifier(user_id),
          input: [
            {
              role: "user",
              content: [
                { type: "input_text", text: analysis_prompt },
                { type: "input_image", image_url: image_data_url(image), detail: "low" }
              ]
            }
          ],
          text: {
            format: {
              type: "json_schema",
              name: "clothing_analysis",
              strict: true,
              schema: ResultSchema::SCHEMA
            }
          },
          max_output_tokens: 800
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

        raise ProviderError, "Analysis provider request failed with status #{response.code}"
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => error
        raise ProviderError, "Analysis provider request failed: #{error.class.name}"
      end

      def extract_output_text(response_body)
        message = Array(response_body["output"]).find { |output| output["type"] == "message" }
        content = Array(message&.fetch("content", nil)).find { |item| item["type"] == "output_text" }
        content&.fetch("text", nil).presence || raise(InvalidResultError, "Analysis provider returned no output")
      end

      def image_data_url(image)
        encoded_image = Base64.strict_encode64(image.download)
        "data:#{image.blob.content_type};base64,#{encoded_image}"
      end

      def safety_identifier(user_id)
        secret = Rails.application.secret_key_base
        Digest::SHA256.hexdigest("wearo-clothing-analysis:#{user_id}:#{secret}")
      end

      def analysis_prompt
        <<~PROMPT.squish
          Analyze the single clothing item in this image. Ignore the background, person, mannequin, hanger, and unrelated objects.
          Choose category and subcategory only from this taxonomy: #{ClothingTaxonomy::CATEGORIES.to_json}.
          Use concise lowercase values for colors, pattern, material, seasons, occasions, and style tags.
          Set uncertain nullable fields to null and provide confidence from 0 to 1.
        PROMPT
      end
    end
  end
end
