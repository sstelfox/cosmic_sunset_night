
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
      redis.zadd('mtgox:avg', time_stamp, current_data['avg']['value_int'])
      redis.zadd('mtgox:buy', time_stamp, current_data['buy']['value_int'])
      redis.zadd('mtgox:high', time_stamp, current_data['high']['value_int'])
      redis.zadd('mtgox:last', time_stamp, current_data['last']['value_int'])
      redis.zadd('mtgox:low', time_stamp, current_data['low']['value_int'])
      redis.zadd('mtgox:sell', time_stamp, current_data['sell']['value_int'])
      redis.zadd('mtgox:vol', time_stamp, current_data['vol']['value'])
    end
  end
end

