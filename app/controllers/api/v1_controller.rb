class Api::V1Controller < ApplicationController
  def trade_data
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol', 'vwap']
    @time_series = $redis.multi do
      metrics.each do |m|
        $redis.lrange("mtgox:#{m}", 0, 100)
      end
    end
  end
end
