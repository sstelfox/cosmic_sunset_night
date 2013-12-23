class Api::V1Controller < ApplicationController
  def trade_data
    date = $redis.sort('mtgox:ticker:periods', {order: 'DESC', limit: [0, 1]}).first
    @time_series = $redis.zrange("mtgox:ticker:#{date}", 0, 250).map { |i| JSON.parse(i) }
  end
end
