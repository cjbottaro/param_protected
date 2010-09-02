require File.expand_path('../boot', __FILE__)
require "action_controller/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module TestApp
  class Application < Rails::Application
    config.cache_classes = false
    config.whiny_nils = true
    config.secret_token = 'd229e4d22437432705ab3985d4d246'
    config.session_store :cookie_store, :key => 'rails_session'
    config.active_support.deprecation = :stderr
  end
end
