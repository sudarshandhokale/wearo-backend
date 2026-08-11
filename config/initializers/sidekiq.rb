Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" } }

  config.death_handlers << lambda { |job, ex|
    Rails.logger.error("Sidekiq job #{job['class']} exhausted retries: #{ex.message}")
  }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" } }
end
