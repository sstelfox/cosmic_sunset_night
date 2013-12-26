
module Market::Current
  LAG_URL = "https://data.mtgox.com/api/2/money/order/lag"

  # Returns the average length of time the market is currently taking to process
  # orders in millionths of a second (six decimal places) as in integer.
  #
  # @return [Fixnum]
  def lag
    JSON.parse(Net::HTTP.get(URI.parse(LAG_URL)))["data"]["lag"]
  end
end
