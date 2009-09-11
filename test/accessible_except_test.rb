require "test_helper"

class AccessibleExceptControllerTest < ActionController::TestCase
  
  test_action :first do
    assert_params %w[a b c d e f g h]
  end
  
  test_action :second do
    assert_params %w[a]
  end
  
end