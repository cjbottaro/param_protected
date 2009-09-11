require "test_helper"

class ProtectedControllerTest < ActionController::TestCase
  
  test_action :an_action do
    assert_params %w[b d e f h]
  end
  
  test_action :only_one_action do
    assert_params %w[d e f h]
  end
  
  test_action :except_one_action do
    assert_params %w[c b d e f h]
  end
  
  test_action :params_as_array do
    assert_params %w[b f h]
  end
  
  test_action :only_multiple_actions1 do
    assert_params %w[b d e h]
  end
  
  test_action :only_multiple_actions2 do
    assert_params %w[b d e h]
  end
  
  test_action :except_multiple_actions1 do
    assert_params %w[b d e f g h]
  end
  
  test_action :except_multiple_actions2 do
    assert_params %w[b d e f g h]
  end
  
  test_action :nested_single do
    assert_params %w[b d e f h]
    assert_equal({"b" => "b", "c" => "c"}, params["h"])
  end
  
  test_action :nested_multiple do
    assert_params %w[b d e f h]
    assert_equal({"c" => "c"}, params["h"])
  end
  
end