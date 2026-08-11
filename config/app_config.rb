module AppConfig
  def self.fetch(key, default: nil)
    ENV[key.to_s.upcase] || Rails.application.credentials.dig(:app_config, key) || default
  end
end
