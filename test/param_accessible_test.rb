require File.dirname(__FILE__) + '/../../../../test/test_helper'
require File.dirname(__FILE__) + '/../init.rb'

require 'ruby-debug'
Debugger.start

class FakeController < ActionController::Base

  def fake_action1
    render :text => ''
  end

  def fake_action2
    render :text => ''
  end

  def fake_action3
    render :text => ''
  end
  
  protected

  def rescue_action(e)
    raise e
  end

end

class ParamAccessibleTest < Test::Unit::TestCase

  def setup
    class << FakeController
      attr_accessor :pp_protected, :pp_accessible
    end
    FakeController.pp_protected  = []
    FakeController.pp_accessible = []
    @controller = FakeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_simple
    @controller.class.param_accessible :user_id
    
    get :fake_action1, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == false
    assert @controller.params.has_key?(:account_id) == false
  end

  def test_only
    @controller.class.param_accessible :user_id, :only => :fake_action1
    
    get :fake_action1, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == false
    assert @controller.params.has_key?(:account_id) == false
    
    get :fake_action2, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == true
    assert @controller.params.has_key?(:account_id) == true
    
    get :fake_action3, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == true
    assert @controller.params.has_key?(:account_id) == true
  end

  def text_except
    @controller.class.param_accessible :user_id, :except => :fake_action1

    get :fake_action1, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == true
    assert @controller.params.has_key?(:account_id) == true
    
    get :fake_action2, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == false
    assert @controller.params.has_key?(:account_id) == false
    
    get :fake_action3, :user_id => true, :client_id => true, :account_id => true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:client_id) == false
    assert @controller.params.has_key?(:account_id) == false
  end

  def test_param_array
    @controller.class.param_accessible [:user_id, :other_id]

    get :fake_action1, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == false

    get :fake_action2, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == false
  end

  def test_only_array
    @controller.class.param_accessible [:user_id, :other_id], :only => [:fake_action1, :fake_action2]

    get :fake_action1, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == false

    get :fake_action2, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == false

    get :fake_action3, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true
  end

  def test_except_array
    @controller.class.param_accessible [:user_id, :other_id], :except => [:fake_action1, :fake_action2]

    get :fake_action1, :user_id => true, :other_id => true, :good_id => true
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action2, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action3, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == false
  end

  def test_param_string
    @controller.class.param_accessible 'user_id'
    
    get :fake_action1, :user_id => true
    assert @controller.params.has_key?(:user_id) == true
    
    get :fake_action2, :user_id => true
    assert @controller.params.has_key?(:user_id) == true
    
    get :fake_action3, :user_id => true
    assert @controller.params.has_key?(:user_id) == true
  end

  def test_only_string
    @controller.class.param_accessible 'user_id', :only => 'fake_action1'

    get :fake_action1, :user_id => true, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == false

    get :fake_action2, :user_id => true, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == true
    
    get :fake_action3, :user_id => true, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == true
  end

  def test_exclude_string
    @controller.class.param_accessible 'user_id', :except => 'fake_action1'

    get :fake_action1, :user_id => 123, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == true

    get :fake_action2, :user_id => 123, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == false
    
    get :fake_action3, :user_id => 123, :client_id => true
    assert @controller.params.has_key?(:user_id)   == true
    assert @controller.params.has_key?(:client_id) == false
  end

  def test_nested
    @controller.class.param_accessible({:user => :user_id}, :only => :fake_action1)

    get :fake_action1, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == false
    assert @controller.params.has_key?(:user_id) == false
    assert @controller.params.has_key?(:good_id) == false

    get :fake_action2, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true

    get :fake_action3, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true
  end

  # Adding a hash to the accessible list really don't have any effect.
  def test_nested_deep
    @controller.class.param_accessible 'user', :only => :fake_action1

    get :fake_action1, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user) == true
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == false
    assert @controller.params.has_key?(:good_id) == false

    get :fake_action2, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true

    get :fake_action3, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == true
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true
  end
  
end
