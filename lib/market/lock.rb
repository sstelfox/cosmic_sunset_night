

module Market::Lock
  # Acquire a named lock on the Redis instance with a timeout, it will return
  # either the identifier of the lock or false if it was unable to acquire the
  # lock.
  #
  # @param [Redis] conn An active redis connection
  # @param [String] lockname
  # @param [Fixnum] acquire_timeout
  # @param [Fixnum] lock_timeout
  #
  # @return [Boolean, String]
  def acquire(conn, lockname, acquire_timeout = 2, lock_timeout = 5)
    lock_name = "lock:#{lockname}"
    aquire_expire = Time.now + acquire_timeout
    lock_timeout = lock_timeout.floor
    lock_id = SecureRandom.uuid

    # Attempt to acquire a lock on the specified name
    while Time.now < aquire_expire
      # If it doesn't exist we'll be able to set it
      if conn.setnx(lockname, lock_id)
        # And ensure it has an expiration
        conn.expire(lockname, lock_timeout)
        return lock_id
      # If the previous lock holder died before setting a timeout, set one.
      elsif ! conn.ttl(lockname)
        conn.expire(lockname, lock_timeout)
      end
    end

    false
  end

  # Release an existing redis lock. Will return true in the event that the lock
  # doesn't exist or was successfully able to release the lock. It will return
  # false if the lock exists but doesn't belong to the provided ID.
  #
  # @param [Redis] conn An active redis connection
  # @param [String] lockname
  # @param [String] lock_id
  #
  # @return [Boolean]
  def release(conn, lockname, lock_id)
    lock_name = "lock:#{lockname}"

    begin
      conn.watch(lock_name)

      # Ensure we're still the owner
      return false unless conn.get(lock_name) == lock_id

      conn.delete(lock_name)
      conn.unwatch(lock_name)
    rescue
      retry
    end
  end

  module_function :acquire, :lock
end

