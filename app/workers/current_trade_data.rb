
require 'net/https'


class CurrentTradeData
  include Sidekiq::Worker

  sidekiq_options :retry => false

  LIMIT = 172800
  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'])
  end

  def get_current_trade_data
  end

  def perform
    current_data = JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
    time_stamp = current_data["now"].to_i
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol']

    r = 

    # The following doesn't work as the same price showing up will be grouped
    # together and received the most recently seen version of that price.
    sizes = r.multi do
      metrics.each do |k|
        r.zcard("mtgox:#{k}")
      end
    end
    size_map = Hash[metrics.zip(sizes)]

    r.multi do
      metrics.each do |k|
        r.remrangebyrank("mtgox:#{k}", 0, LIMIT * -1) if size_map[k] >= LIMIT
        r.zadd("mtgox:#{k}", time_stamp, current_data[k]['value'])
      end
    end
  end

  def acquire_redis_lock
  end
end

