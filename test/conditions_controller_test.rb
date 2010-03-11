require "test_helper"

class ConditionsControllerTest < ActionController::TestCase
  
  test_action :first do
    assert_params %w[a c]
  end
  
  test_action :second do
    assert_params %w[a b]
  end
  
end
