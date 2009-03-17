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

class ParamProtectedTest < Test::Unit::TestCase

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
    @controller.class.param_protected :user_id
    
    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
  end

  def test_only
    @controller.class.param_protected :user_id, :only => :fake_action1
    
    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false

    get :fake_action2, :user_id => 123
    assert @controller.params.has_key?(:user_id) == true
  end

  def text_except
    @controller.class.param_protected :user_id, :except => :fake_action1

    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == true

    get :fake_action2, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
  end

  def test_param_array
    @controller.class.param_protected [:user_id, :other_id]

    get :fake_action1, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == false
    assert @controller.params.has_key?(:other_id) == false
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action2, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == false
    assert @controller.params.has_key?(:other_id) == false
    assert @controller.params.has_key?(:good_id)  == true
  end

  def test_only_array
    @controller.class.param_protected [:user_id, :other_id], :only => [:fake_action1, :fake_action2]

    get :fake_action1, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == false
    assert @controller.params.has_key?(:other_id) == false
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action2, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == false
    assert @controller.params.has_key?(:other_id) == false
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action3, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true
  end

  def test_except_array
    @controller.class.param_protected [:user_id, :other_id], :except => [:fake_action1, :fake_action2]

    get :fake_action1, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action2, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == true
    assert @controller.params.has_key?(:other_id) == true
    assert @controller.params.has_key?(:good_id)  == true

    get :fake_action3, :user_id => 123, :other_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user_id)  == false
    assert @controller.params.has_key?(:other_id) == false
    assert @controller.params.has_key?(:good_id)  == true
  end

  def test_param_string
    @controller.class.param_protected 'user_id'
    
    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
    
    get :fake_action2, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
    
    get :fake_action3, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
  end

  def test_only_string
    @controller.class.param_protected 'user_id', :only => 'fake_action1'

    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false

    get :fake_action2, :user_id => 123
    assert @controller.params.has_key?(:user_id) == true
    
    get :fake_action3, :user_id => 123
    assert @controller.params.has_key?(:user_id) == true
  end

  def test_exclude_string
    @controller.class.param_protected 'user_id', :except => 'fake_action1'

    get :fake_action1, :user_id => 123
    assert @controller.params.has_key?(:user_id) == true

    get :fake_action2, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
    
    get :fake_action3, :user_id => 123
    assert @controller.params.has_key?(:user_id) == false
  end

  def test_nested
    @controller.class.param_protected({:user => :user_id}, :only => :fake_action1)

    get :fake_action1, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params[:user].has_key?(:user_id) == false
    assert @controller.params[:user].has_key?(:good_id) == true
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true

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

  def test_nested_deep
    @controller.class.param_protected 'user', :only => :fake_action1

    get :fake_action1, :user => { :user_id => 123, :good_id => 321 }, :user_id => 456, :good_id => 789
    assert @controller.params.has_key?(:user)    == false
    assert @controller.params.has_key?(:user_id) == true
    assert @controller.params.has_key?(:good_id) == true

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
