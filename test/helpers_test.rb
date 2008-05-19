require File.dirname(__FILE__) + '/../../../../test/test_helper'
require File.dirname(__FILE__) + '/../init.rb'

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

class HelpersTest < Test::Unit::TestCase

  def setup
    FakeController._pp_accessible_map = nil
    FakeController._pp_protected_map = nil
    @controller = FakeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_the_xpathy_thing
    params = {
      :scalar => 'test',
      :user => { :name => { :fname => 'chris', :lname => 'bottaro'},
                 :id   => 1 },
      :pets => [ {:fname => 'calia', :mname => 'rose'},
                 {:fname => 'coco',  :mname => 'rae' } ]              
    }
    expected_xpathy_thing = {
      'scalar' => [[params, :scalar]],
      'user' => [[params, :user]],
      'user/name' => [[params[:user], :name]],
      'user/name/fname' => [[params[:user][:name], :fname]],
      'user/name/lname' => [[params[:user][:name], :lname]],
      'user/id' => [[params[:user], :id]],
      'pets' => [[params, :pets]],
      'pets/fname' => [[params[:pets][0], :fname], [params[:pets][1], :fname]],
      'pets/mname' => [[params[:pets][0], :mname], [params[:pets][1], :mname]]
    }
    xpathy_thing = Cjbottaro::ParamProtected::PrivateMethods.params_by_xpathy(params)
    assert_equal expected_xpathy_thing, xpathy_thing
  end

  def test_accessible_map
    
    FakeController.param_accessible :user_id
    expected_map = { 'fake_action1' => ['user_id'],
                     'fake_action2' => ['user_id'],
                     'fake_action3' => ['user_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
    
    FakeController.param_accessible :client_id
    expected_map = { 'fake_action1' => ['user_id', 'client_id'],
                     'fake_action2' => ['user_id', 'client_id'],
                     'fake_action3' => ['user_id', 'client_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
    
    FakeController.param_accessible :account_id, :only => :fake_action1
    expected_map = { 'fake_action1' => ['user_id', 'client_id', 'account_id'],
                     'fake_action2' => ['user_id', 'client_id'],
                     'fake_action3' => ['user_id', 'client_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
    
    FakeController.param_accessible :account_id, :except => :fake_action1
    expected_map = { 'fake_action1' => ['user_id', 'client_id', 'account_id'],
                     'fake_action2' => ['user_id', 'client_id', 'account_id'],
                     'fake_action3' => ['user_id', 'client_id', 'account_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
  end
  
  def test_accessible_map_with_arrays
    
    FakeController.param_accessible [:user_id, :client_id], :only => [:fake_action1, :fake_action2]
    expected_map = { 'fake_action1' => ['user_id', 'client_id'],
                     'fake_action2' => ['user_id', 'client_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
    
    FakeController.param_accessible [:user_id, :client_id], :except => [:fake_action1, :fake_action2]
    expected_map = { 'fake_action1' => ['user_id', 'client_id'],
                     'fake_action2' => ['user_id', 'client_id'],
                     'fake_action3' => ['user_id', 'client_id'] }
    assert_equal expected_map, FakeController._pp_accessible_map
  end

end
