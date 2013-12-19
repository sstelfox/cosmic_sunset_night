
require 'mtgox'

class MtgoxCurrentStatus
  include Sidekiq::Worker

  def perform
    ru = URI.parse(ENV['REDIS_PROVIDER'])
    ru.path = '/0'
    redis = Redis.new(url: ru.to_s)

    redis.publish('test', 'message')
  end
end

