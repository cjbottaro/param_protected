require "test_helper"

class InheritedUsersControllerTest < ActionController::TestCase
  
  PARAMS = { :user => { :id => 123,
                          :name => { :first => "chris", :middle => "james", :last => "bottaro"},
                          :email => "cjbottaro@blah.com",
                          :password => "SEcReT" },
             :something => "something" }
             
  EXPECTED_PARAMS = { "user" => { "email" => "cjbottaro@blah.com",
                                  "password" => "SEcReT" } }

  def test_create
    get :create, PARAMS
    assert_equal EXPECTED_PARAMS, params
  end
  
  def test_update
    get :update, PARAMS
    assert_equal EXPECTED_PARAMS, params
  end
  
end
