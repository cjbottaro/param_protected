require "test_helper"

class UsersControllerTest < ActionController::TestCase
  PARAMS = { :user => { :id => 123,
                        '33' => { :ok => 'yes', :not_ok => 'no' },
                        '123' => 'ok',
                        :x21 => 'ok',
                        :name => { :first => "chris", :middle => "james", :last => "bottaro"},
                        :email => "cjbottaro@blah.com" },
             :something => "something" }
             
  EXPECTED_PARAMS = { "user" => { "name" => {"first" => "chris", "last" => "bottaro"},
                                  '33' => { 'ok' => 'yes' }, '123' => 'ok',
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