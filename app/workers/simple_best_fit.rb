
class SimpleBestFit < BotBase
  MAX_TRADE_SIZE = 0.5 # In BTC

  def perform
    # Don't do anything and end the run unless there are funds available
    unless funds_available
      @redis.setnx("#{name}:end", Time.now.to_i)
      return false
    end

    # Randomly perform a transaction, will quietly fail if it's unable to
    # perform the transaction.
    coin_amount = rand(0..MAX_TRADE_SIZE)
    rand(2) == 0 ? purchase(coin_amount) : sell(coin_amount)

    print_report
  end

  # X are the time periods, Y are the costs
  def best_fit_line
    # Get the data
    dp = last_data_points(25)
    count = dp.size

    # Create a collection of our two relevant data points
    data_points = dp.each_with_object({time: [], cost: []}) do |d, o|
      o[:time].push(d['time'])
      o[:cost].push(d['last'])
    end
  end
end

