
require 'sidekiq'

class BotBase
  include Sidekiq::Worker

  sidekiq_options :retry => false

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1')

    # If the values haven't been created yet initialize them
    @redis.setnx("#{name}:btc", 20)
    @redis.setnx("#{name}:usd", 0)
    @redis.setnx("#{name}:fees", 0)
    @redis.setnx("#{name}:start", Time.now.to_i)
  end

  def clear
    keys = @redis.keys("#{name}*")
    @redis.multi do
      keys.each { |k| @redis.del(k) }
    end
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

  def fees_paid
    @redis.get("#{name}:fees").to_f
  end

  def net_worth_usd
    btc_usd = (available_btc * btc_value)
    available_usd + btc_usd - (btc_usd * trade_fee)
  end

  def net_worth_btc
    usd_btc = (available_usd / btc_value)
    available_btc + usd_btc - (usd_btc * trade_fee)
  end

  def funds_available
    available_btc > 0 || available_usd > 0
  end

  def purchase(coins)
    gross_cost = coins * btc_value
    fee = gross_cost * self.trade_fee
    net_cost = gross_cost + fee

    if available_usd >= net_cost
      @redis.set("#{name}:fees", fees_paid + fee)
      @redis.set("#{name}:btc", available_btc + coins)
      @redis.set("#{name}:usd", available_usd - net_cost)
      @redis.lpush("#{name}:trades", "Purchased #{coins} at #{Time.now.iso8601} for #{net_cost}" )
    end
  end

  def sell(coins)
    if available_btc >= coins
      gross_value = coins * btc_value
      fee = gross_value * self.trade_fee
      net_value = gross_value - fee

      @redis.set("#{name}:fees", fees_paid + fee)
      @redis.set("#{name}:btc", available_btc - coins)
      @redis.set("#{name}:usd", available_usd + net_value)
      @redis.lpush("#{name}:trades", "Sold #{coins} at #{Time.now.iso8601} for #{net_value}")
    end
  end
end

