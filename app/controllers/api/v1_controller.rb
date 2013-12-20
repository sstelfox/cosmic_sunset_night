class Api::V1Controller < ApplicationController
  def trade_data
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol', 'vwap']
    values = $redis.multi do
      metrics.each do |m|
        $redis.lrange("mtgox:#{m}", 0, 100)
      end
    end
    @time_series = metrics.zip(values)
  end
end
