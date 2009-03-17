require File.dirname(__FILE__) + '/../../../../test/test_helper'

class HelpersTest < Test::Unit::TestCase
  
  # a little aliasing so I don't have to type so much.
  Helpers = Cjbottaro::ParamProtected::Helpers
  
  def test_normalize_params
    params = Helpers.normalize_params(:something)
    assert_equal({"something" => nil}, params)
    
    params = Helpers.normalize_params([:something, :else])
    assert_equal({"something" => nil, "else" => nil}, params)
    
    params = Helpers.normalize_params(:something => [:stuff, :blah])
    assert_equal({"something" => {"stuff" => nil, "blah" => nil}}, params)
    
    params = Helpers.normalize_params(:something => [:stuff, {:blah => :bleck}])
    assert_equal({"something" => {"stuff" => nil, "blah" => {"bleck" => nil}}}, params)
  end
  
  def test_normalize_actions
    actions = Helpers.normalize_actions(nil)
    assert_equal [:except, nil], actions
    
    actions = Helpers.normalize_actions(:only => :blah)
    assert_equal [:only, "blah"], actions
    
    actions = Helpers.normalize_actions(:only => [:blah, :bleck])
    assert_equal [:only, "blah", "bleck"], actions
    
    actions = Helpers.normalize_actions(:except => :blah)
    assert_equal [:except, "blah"], actions
    
    actions = Helpers.normalize_actions(:except => [:blah, :bleck])
    assert_equal [:except, "blah", "bleck"], actions
    
    assert_raises(ArgumentError){ Helpers.normalize_actions(:onlyy => :blah) }
    assert_raises(ArgumentError){ Helpers.normalize_actions(:blah) }
    assert_raises(ArgumentError){ Helpers.normalize_actions(:only => :something, :except => :something) }
  end
  
  def test_action_matches
    assert  Helpers.action_matches?(:only, ["blah", "bleck"], "blah")
    assert  Helpers.action_matches?(:only, ["blah", "bleck"], "bleck")
    assert !Helpers.action_matches?(:only, ["blah", "bleck"], "not")
    
    assert !Helpers.action_matches?(:except, ["blah", "bleck"], "blah")
    assert !Helpers.action_matches?(:except, ["blah", "bleck"], "bleck")
    assert  Helpers.action_matches?(:except, ["blah", "bleck"], "not")
    
    assert_raises(ArgumentError){ Helpers.action_matches?(:bad_scope, ["blah", "bleck"], "not") }
  end
  
  def test_do_param_accessible
    
    accessible_params = { :account_id => nil,
                          :user_id => nil }
    params            = { :account_id => 123,
                          :user_id => 456,
                          :profile_id => 789 }
    expected_results  = { :account_id => 123,
                          :user_id => 456 }
    assert_equal expected_results, Helpers.do_param_accessible(accessible_params, params)
    
    accessible_params = { :account_id => nil,
                          :user => nil }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro" },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro"} }
    assert_equal expected_results, Helpers.do_param_accessible(accessible_params, params)
    
    accessible_params = { :account_id => nil,
                          :user => {:first_name => nil, :last_name => nil} }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro", :middle_name => "james" },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro"} }
    assert_equal expected_results, Helpers.do_param_accessible(accessible_params, params)
    
    accessible_params = { :account_id => nil,
                          :user => {:name => {:first => nil, :last => nil}} }
    params            = { :account_id => 123,
                          :user => { :city => "Austin",
                                     :name => {:first => "christopher", :last => "bottaro", :middle => "james"} },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :name => {:first => "christopher", :last => "bottaro"} } }
    assert_equal expected_results, Helpers.do_param_accessible(accessible_params, params)
  end
  
  def test_do_param_protected
    
    protected_params  = { :account_id => nil,
                          :user => nil }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro" },
                          :profile_ids => [789, 987] }
    expected_results  = { :profile_ids => [789, 987] }
    assert_equal expected_results, Helpers.do_param_protected(protected_params, params)
    
    protected_params  = { :account_id => nil,
                          :user => {:middle_name => nil} }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro", :middle_name => "james" },
                          :profile_ids => [789, 987] }
    expected_results  = { :user => {:first_name => "christopher", :last_name => "bottaro"},
                          :profile_ids => [789, 987] }
    assert_equal expected_results, Helpers.do_param_protected(protected_params, params)
    
    protected_params  = { :account_id => nil,
                          :user => {:name => {:middle => nil}} }
    params            = { :account_id => 123,
                          :user => { :city => "Austin",
                                     :name => {:first => "christopher", :last => "bottaro", :middle => "james"} },
                          :profile_ids => [789, 987] }
    expected_results  = { :profile_ids => [789, 987],
                          :user => { :city => "Austin",
                          :name => {:first => "christopher", :last => "bottaro"} } }
    assert_equal expected_results, Helpers.do_param_protected(protected_params, params)
  end
  
end
