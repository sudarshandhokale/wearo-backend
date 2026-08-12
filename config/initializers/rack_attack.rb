class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  safelist("health checks") do |request|
    request.path.in?([ "/up", "/api/v1/health", "/api/v1/health/readiness" ])
  end

  blocklist("oversized request body") do |request|
    request.content_length.to_i > 25.megabytes
  end

  throttle("auth/ip", limit: 20, period: 1.minute) do |request|
    request.ip if request.post? && request.path.start_with?("/api/v1/auth/")
  end

  throttle("login/ip", limit: 8, period: 1.minute) do |request|
    request.ip if request.post? && request.path == "/api/v1/auth/login"
  end

  throttle("registration/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.post? && request.path == "/api/v1/auth/register"
  end

  throttle("password-email/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.post? && request.path.in?([
      "/api/v1/auth/password/forgot",
      "/api/v1/auth/confirmations"
    ])
  end

  throttle("uploads/token", limit: 30, period: 1.hour) do |request|
    token_fingerprint(request) if request.post? && request.path == "/api/v1/clothing_items"
  end

  throttle("ai/token", limit: 30, period: 1.hour) do |request|
    token_fingerprint(request) if request.post? && (
      request.path == "/api/v1/stylist/recommendations" ||
      request.path.match?(%r{\A/api/v1/outfits/\d+/visualizations\z})
    )
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env.fetch("rack.attack.match_data", {})
    retry_after = match_data[:period].to_i
    body = {
      success: false,
      error: { message: I18n.t("errors.messages.rate_limited") }
    }

    [ 429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s }, [ JSON.generate(body) ] ]
  end


  self.blocklisted_responder = lambda do |_request|
    body = {
      success: false,
      error: { message: I18n.t("errors.messages.request_too_large") }
    }
    [ 413, { "Content-Type" => "application/json" }, [ JSON.generate(body) ] ]
  end

  def self.token_fingerprint(request)
    token = request.get_header("HTTP_AUTHORIZATION").to_s
    token.present? ? OpenSSL::Digest::SHA256.hexdigest(token) : "ip:#{request.ip}"
  end
end
