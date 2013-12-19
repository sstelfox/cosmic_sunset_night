
require 'net/https'

class MtgoxCurrentStatus
  include Sidekiq::Worker

  sidekiq_options :retry => false

  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  def perform
    current_data = JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
    time_stamp = current_data["now"].to_i

    r = Redis.new(url: ENV['REDIS_PROVIDER'])
    r.multi do
      ['avg', 'buy', 'high', 'last', 'low', 'sell'].each do |k|
        redis.zadd("mtgox:#{k}", time_stamp, current_data[k]['value_int'])
      end
      redis.zadd('mtgox:vol', time_stamp, current_data['vol']['value'])
    end
  end
end

