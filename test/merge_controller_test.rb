require "test_helper"

class MergeControllerTest < ActionController::TestCase
  
  test_action :first do
    assert_params %w[a b h]
    assert_equal({"b" => "b"}, params["h"])
  end
  
  test_action :second do
    assert_params %w[b h]
    assert_equal({"b" => "b", "c" => "c"}, params["h"])
  end
  
end
