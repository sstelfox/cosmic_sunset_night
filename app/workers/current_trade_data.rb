
require 'net/https'
require 'securerandom'

class CurrentTradeData
  include Sidekiq::Worker

  sidekiq_options :retry => false

  LIMIT = 14400
  URL = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker'

  RedisLockUnavailable = Class.new(StandardError)

  def initialize
    @redis = Redis.new(url: ENV['REDIS_PROVIDER'])
  end

  def get_current_trade_data
    JSON.parse(Net::HTTP.get(URI.parse(URL)))["data"]
  end

  def parse_trade_data(td)
    result = {'time' => td["now"].to_i}

    # vwap is the volume weighted average price
    metrics = ['avg', 'buy', 'high', 'last', 'low', 'sell', 'vol', 'vwap']
    metrics.each_with_object(result) do |metric, result|
      result[metric.to_s] = td[metric]['value']
    end
  end

  def perform
    data = parse_trade_data(get_current_trade_data)
    data.delete('time')

    lock_id = acquire_redis_lock('current_trade_data')
    fail(RedisLockUnavailable, 'current_trade_data') unless lock_id

    # The following doesn't work as the same price showing up will be grouped
    # together and received the most recently seen version of that price.
    @redis.multi do
      data.keys.each do |k|
        @redis.lpush("mtgox:#{k}", data[k])
        @redis.ltrim("mtgox:#{k}", 0, LIMIT)
      end
    end

    release_redis_lock('current_trade_data', lock_id)
  end

  # Acquire a named lock on the Redis instance with a timeout, it will return
  # either the identifier of the lock or false if it was unable to acquire the
  # lock.
  #
  # @param [String] lockname
  # @param [Fixnum] acquire_timeout
  # @param [Fixnum] lock_timeout
  #
  # @return [Boolean, String]
  def acquire_redis_lock(lockname, acquire_timeout = 2, lock_timeout = 5)
    lock_name = "lock:#{lockname}"
    aquire_expire = Time.now + acquire_timeout
    lock_timeout = lock_timeout.floor
    lock_id = SecureRandom.uuid

    # Attempt to acquire a lock on the specified name
    while Time.now < aquire_expire
      # If it doesn't exist we'll be able to set it
      if @redis.setnx(lockname, lock_id)
        # And ensure it has an expiration
        @redis.expire(lockname, lock_timeout)
        return lock_id
      # If the previous lock holder died before setting a timeout, set one.
      elsif ! @redis.ttl(lockname)
        @redis.expire(lockname, lock_timeout)
      end
    end

    false
  end

  # Release an existing redis lock. Will return true in the event that the lock
  # doesn't exist or was successfully able to release the lock. It will return
  # false if the lock exists but doesn't belong to the provided ID.
  #
  # @param [String] lockname
  # @param [String] lock_id
  #
  # @return [Boolean]
  def release_redis_lock(lockname, lock_id)
    lock_name = "lock:#{lockname}"

    begin
      @redis.watch(lock_name)

      # Ensure we're still the owner
      return false unless @redis.get(lock_name) == lock_id

      @redis.delete(lock_name)
      @redis.unwatch(lock_name)
    rescue
      retry
    end
  end
end

