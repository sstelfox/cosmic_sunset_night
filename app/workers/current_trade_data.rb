
require 'net/https'
require 'securerandom'

class CurrentTradeData
  include Sidekiq::Worker

  sidekiq_options :retry => false

  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1')
  end

  def get_current_trade_data
    JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
  end

  def parse_trade_data(td)
    result = {'time' => (td["now"].to_i * 10 ** -6).to_f}

    # vwap is the volume weighted average price
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol', 'vwap']
    metrics.each_with_object(result) do |metric, result|
      result[metric.to_s] = td[metric]['value'].to_f
    end
  end

  def perform
    data = parse_trade_data(get_current_trade_data)
    json_data = JSON.generate(data)

    time_period = Time.at(data['time']).strftime("%Y%m%d")

    # The following doesn't work as the same price showing up will be grouped
    # together and received the most recently seen version of that price.
    @redis.zadd("mtgox:ticker:#{time_period}", data["time"], json_data)
    @redis.sadd("mtgox:ticker:periods", time_period)
    @redis.publish("mtgox:ticker:live", json_data)
  end
end

