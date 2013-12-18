
class TestWorker
  include Sidekiq::Worker

  def perform
    sleep 2
  end
end

