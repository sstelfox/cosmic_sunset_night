
# This bot performs a single transaction entirely randomly each time it's run
# and is intended to be a control. Any other bot with intent should be able to
# beat this one as it will be treated as the baseline.
class ControlBot < BotBase
  MAX_TRADE_SIZE = 0.5 # In BTC

  def perform
    setup

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
end

