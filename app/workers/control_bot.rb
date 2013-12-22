
# This bot performs a single transaction entirely randomly each time it's run
# and is intended to be a control. Any other bot with intent should be able to
# beat this one as it will be treated as the baseline.
class ControlBot < BotBase
  MAX_TRADE_SIZE = 0.5 # In BTC

  def perform
    # Don't do anything and end the run unless there are funds available
    unless funds_available
      @redis.setnx("#{name}:end", Time.now.to_i)
      return false
    end

    puts "Starting run net worth: #{net_worth}"
  end
end

