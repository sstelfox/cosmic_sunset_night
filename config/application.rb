require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module CosmicSunsetNight
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    redis_base = URI.parse(ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379')
    redis_base.path = '/'

    config.cache_store = :redis_store, (redis_base.to_s + '1/cache'), { expires_in: 90.minutes }

    config.session_store(:redis_store)

    config.action_dispatch.rack_cache = {
      metastore:   (redis_base.to_s + '1/metastore'),
      entitystore: (redis_base.to_s + '1/entitystore')
    }
  end
end
