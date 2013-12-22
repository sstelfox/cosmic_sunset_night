
class BotBase
  include Sidekiq::Worker

  sidekiq_options :retry => false

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1')

    # If the values haven't been created yet initialize them
    @redis.setnx("#{name}:btc", 20)
    @redis.setnx("#{name}:usd", 0)
  end

  def last_data_point
    JSON.parse($redis.zrevrange("mtgox:ticker:#{date}", 0, 1).first)
  end

  def name
    "bot:#{self.class.to_s.downcase}"
  end

  def trade_fee
    0.006
  end
end

class BotAttemptOne < BotBase
  def perform
  end
end
