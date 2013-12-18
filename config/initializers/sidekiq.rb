
require 'uri'

# In this app we're going to always make use of the third database
sidekiq_redis_url = URI.parse(ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379')
sidekiq_redis_url.path = '/3'

Sidekiq.configure_server do |config|
  config.redis = { :url => sidekiq_redis_url.to_s }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => sidekiq_redis_url.to_s }
end

