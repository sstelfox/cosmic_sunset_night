# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

CosmicSunsetNight::Application.load_tasks

namespace :bot do
  desc "Reset all bot counters within the Redis instance"
  task :reset => :environment do
    keys = $redis.keys('bot:*')
    $redis.multi do
      keys.each { |k| $redis.del(k) }
    end
  end
end

