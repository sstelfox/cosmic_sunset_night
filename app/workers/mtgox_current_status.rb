
require 'net/https'


class MtgoxCurrentStatus
  include Sidekiq::Worker

  sidekiq_options :retry => false

  LIMIT = 172800
  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  def perform
    current_data = JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
    time_stamp = current_data["now"].to_i
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol']

    r = Redis.new(url: ENV['REDIS_PROVIDER'])

    sizes = r.multi do
      metrics.each do |k|
        r.zcard("mtgox:#{h}")
      end
    end
    size_map = metrics.zip(sizes.map(&:to_i))

    r.multi do
      metrics.each do |k|
        z.remrangebyrank("mtgox:#{k}", 0, LIMIT * -1) if size_map[k] >= LIMIT
        r.zadd("mtgox:#{k}", time_stamp, current_data[k]['value'])
      end
    end
  end
end

