require 'sidekiq'

Sidekiq.configure_server do |config|
  # Redis connection will be provided by Jiki.config.sidekiq_redis_url
  # once the jiki-config gem is implemented
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

  # Set log level to reduce noise in development
  config.logger.level = Rails.env.production? ? Logger::WARN : Logger::INFO
end

Sidekiq.configure_client do |config|
  # Redis connection will be provided by Jiki.config.sidekiq_redis_url
  # once the jiki-config gem is implemented
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
