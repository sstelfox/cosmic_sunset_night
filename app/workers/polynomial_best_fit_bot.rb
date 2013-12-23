
require 'matrix'

class PolynomialBestFitBot < BotBase
  MAX_TRADE_SIZE = 1.0 # In BTC
  TRADE_THRESHOLD = 0.10

  def perform
    setup

    # Don't do anything and end the run unless there are funds available
    unless funds_available
      @redis.setnx("#{name}:end", Time.now.to_i)
      return false
    end

    coin_amount = rand(0..MAX_TRADE_SIZE)

    pf = best_fit_line
    prediction = pf.call((Time.now + 15).to_f)

    purchase(coin_amount) if prediction >= (btc_value * (1 + trade_fee + TRADE_THRESHOLD))
    sell(coin_amount) if prediction <= (btc_value * (1 - trade_fee - TRADE_THRESHOLD))

    print_report
  end

  def best_fit_line
    # Get the data
    dp = last_data_points(25)
    count = dp.size

    # Create a collection of our two relevant data points, Time is our
    # independent variable (x), while y is our dependent variable.
    data_points = dp.each_with_object({time: [], cost: []}) do |d, o|
      o[:time].push(d['time'])
      o[:cost].push(d['last'])
    end

    polynomial_fit_degree = 2

    # Calculate the betas of the regression for the data
    x_data = data_points[:time].map { |xi| (0..polynomial_fit_degree).map { |pow| (xi ** pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(data_points[:cost])
    betas = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]

    # Create a proc that will represent the polynomial equation that best fits
    # our data points. This was designed too take a unix timestamp and return
    # it's best guess at the future.
    Proc.new { |time| sum = 0; betas.each_with_index { |multiplier, index| sum += multiplier * (time ** index) }; sum }
  end
end

