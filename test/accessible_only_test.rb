require "test_helper"

class AccessibleOnlyControllerTest < ActionController::TestCase
  
  test_action :first do
    assert_params %w[a]
  end
  
  test_action :second do
    assert_params %w[a b c d e f g h]
  end
  
end