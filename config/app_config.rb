module AppConfig
  def self.fetch(key, default: nil)
    env_value = ENV[key.to_s.upcase]
    return env_value if env_value.present?

    Rails.application.credentials.dig(:app_config, key) || default
  end
end
