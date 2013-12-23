
require 'matrix'

class PolynomialBestFit < BotBase
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

    # TODO: Generate a proc with the beta values generated above that
    # calculated  a value for a given input
    # Proc.new { |time| sum = 0; betas.each_with_index { |multiplier, index| multiplier * (time ** index) }}
  end
end

