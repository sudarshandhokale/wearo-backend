if Rails.env.production?
  required_keys = %i[
    database_url redis_url app_host frontend_url cors_origins openai_api_key
    aws_storage_bucket aws_region smtp_address smtp_username smtp_password mailer_from
    devise_jwt_secret_key terms_url privacy_url
  ]
  missing_keys = required_keys.select { |key| AppConfig.fetch(key).blank? }
  raise "Missing production configuration: #{missing_keys.map { |key| key.to_s.upcase }.join(', ')}" if missing_keys.any?

  https_keys = %i[frontend_url terms_url privacy_url]
  invalid_urls = https_keys.reject do |key|
    uri = URI(AppConfig.fetch(key))
    uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
  raise "Production URLs must use HTTPS: #{invalid_urls.map { |key| key.to_s.upcase }.join(', ')}" if invalid_urls.any?

  origins = AppConfig.fetch(:cors_origins).split(",").map(&:strip)
  raise "CORS_ORIGINS cannot contain a wildcard in production" if origins.include?("*")
end
