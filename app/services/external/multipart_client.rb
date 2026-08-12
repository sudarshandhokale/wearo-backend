require "net/http"
require "securerandom"

module External
  class MultipartClient
    MAX_BODY_SIZE = 50.megabytes

    def initialize(http_client: Ai::HttpClient.new)
      @http_client = http_client
    end

    def post(endpoint:, headers:, fields:, files:)
      boundary = "WearoBoundary#{SecureRandom.hex(16)}"
      body = build_body(boundary, fields, files)
      raise InvalidRequestError if body.bytesize > MAX_BODY_SIZE

      @http_client.post(
        endpoint: endpoint,
        headers: headers.merge("Content-Type" => "multipart/form-data; boundary=#{boundary}"),
        body: body
      )
    end

    private

    def build_body(boundary, fields, files)
      body = String.new(encoding: Encoding::BINARY)
      fields.each { |name, value| append_field(body, boundary, name, value) }
      files.each { |file| append_file(body, boundary, file) }
      body << "--#{boundary}--\r\n"
    end

    def append_field(body, boundary, name, value)
      body << "--#{boundary}\r\n"
      body << %(Content-Disposition: form-data; name="#{name}"\r\n\r\n)
      body << value.to_s << "\r\n"
    end

    def append_file(body, boundary, file)
      body << "--#{boundary}\r\n"
      body << %(Content-Disposition: form-data; name="#{file.fetch(:name)}"; filename="#{safe_filename(file.fetch(:filename))}"\r\n)
      body << "Content-Type: #{file.fetch(:content_type)}\r\n\r\n"
      body << file.fetch(:data).b << "\r\n"
    end

    def safe_filename(value)
      File.basename(value.to_s).gsub(/[^a-zA-Z0-9._-]/, "_").first(120)
    end
  end
end
