require "test_helper"

class UsersControllerTest < ActionController::TestCase
  PARAMS = { :user => { :id => 123,
                          :name => { :first => "chris", :middle => "james", :last => "bottaro"},
                          :email => "cjbottaro@blah.com" },
             :something => "something" }
             
  EXPECTED_PARAMS = { "user" => { "name" => {"first" => "chris", "last" => "bottaro"},
                                  "email" => "cjbottaro@blah.com" } }
  
  def test_create
    get :create, PARAMS
    assert_equal EXPECTED_PARAMS, params
  end
  
  def test_update
    get :update, PARAMS
    assert_equal EXPECTED_PARAMS, params
  end
  
end