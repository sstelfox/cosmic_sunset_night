
require 'net/https'

class MtgoxCurrentStatus
  include Sidekiq::Worker

  sidekiq_options :retry => false

  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  def perform
    current_data = JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
    time_stamp = current_data["now"].to_i

    Redis.current.publish('test', 'message')
  end
end

