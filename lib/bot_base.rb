
require 'sidekiq'

class BotBase
  include Sidekiq::Worker

  sidekiq_options :retry => false

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1')

    # If the values haven't been created yet initialize them
    @redis.setnx("#{name}:btc", 20)
    @redis.setnx("#{name}:usd", 0)
    @redis.setnx("#{name}:start", Time.now.to_i)
  end

  # Cache once per run
  def last_data_point
    return @ldp if @ldp
    date = @redis.sort('mtgox:ticker:periods', {order: 'DESC', limit: [0, 1]}).first
    @ldp = JSON.parse(@redis.zrevrange("mtgox:ticker:#{date}", 0, 1).first)
  end

  def name
    "bot:#{self.class.to_s.downcase}"
  end

  def trade_fee
    0.006
  end

  def available_btc
    @redis.get("#{name}:btc").to_f
  end

  def available_usd
    @redis.get("#{name}:usd").to_f
  end

  def btc_value
    last_data_point['last']
  end

  def net_worth
    available_usd + (available_btc * btc_value / trade_fee)
  end

  def funds_available
    available_btc > 0 || available_usd > 0
  end
end

