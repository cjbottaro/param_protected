# Set the default environment to sqlite3's in_memory database
ENV['RAILS_ENV'] ||= 'in_memory'

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/app_root/config/environment"
require 'test_help'
require "param_protected"

# Undo changes to RAILS_ENV
silence_warnings {RAILS_ENV = ENV['RAILS_ENV']}

# Run the migrations
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")

# Set default fixture loading properties
ActiveSupport::TestCase.class_eval do
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
  self.fixture_path = "#{File.dirname(__FILE__)}/fixtures"
  
  fixtures :all
end

class ActionController::TestCase
  PARAMS = {
    "a" => "a",
    "b" => "b",
    "c" => "c",
    "d" => "d",
    "e" => "e",
    "f" => "f",
    "g" => "g",
    "h" => { "a" => "a", "b" => "b", "c" => "c" },
  }.freeze
  
  def assert_params(params)
    controller_params = @controller.params.keys.select{ |k| PARAMS.keys.include?(k.to_s) }
    assert_equal params.sort, controller_params.sort
  end
  
  def params
    @controller.params
  end
  
  def self.test_action(action_name, &block)
    define_method("test_#{action_name}") do
      get action_name, PARAMS.dup
      instance_eval(&block)
    end
  end
end