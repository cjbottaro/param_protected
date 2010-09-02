ENV['RAILS_ENV'] ||= 'test'

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/app_root/config/environment"
require 'rails/test_help'
require 'param_protected'

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
