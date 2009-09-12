require "test_helper"

class HelpersTest < Test::Unit::TestCase
  
  def setup
    @protector = ParamProtected::Protector.new
  end
  
  def test_normalize_params
    params = @protector.send(:normalize_params, :something)
    assert_equal({"something" => nil}, params)
    
    params = @protector.send(:normalize_params, [:something, :else])
    assert_equal({"something" => nil, "else" => nil}, params)
    
    params = @protector.send(:normalize_params, :something => [:stuff, :blah])
    assert_equal({"something" => {"stuff" => nil, "blah" => nil}}, params)
    
    params = @protector.send(:normalize_params, :something => [:stuff, {:blah => :bleck}])
    assert_equal({"something" => {"stuff" => nil, "blah" => {"bleck" => nil}}}, params)
  end
  
  def test_normalize_actions
    actions = @protector.send(:normalize_actions, nil)
    assert_equal [:except, nil], actions
    
    actions = @protector.send(:normalize_actions, :only => :blah)
    assert_equal [:only, "blah"], actions
    
    actions = @protector.send(:normalize_actions, :only => [:blah, :bleck])
    assert_equal [:only, "blah", "bleck"], actions
    
    actions = @protector.send(:normalize_actions, :except => :blah)
    assert_equal [:except, "blah"], actions
    
    actions = @protector.send(:normalize_actions, :except => [:blah, :bleck])
    assert_equal [:except, "blah", "bleck"], actions
    
    assert_raises(ArgumentError){ @protector.send(:normalize_actions, :onlyy => :blah) }
    assert_raises(ArgumentError){ @protector.send(:normalize_actions, :blah) }
    assert_raises(ArgumentError){ @protector.send(:normalize_actions, :only => :something, :except => :something) }
  end
  
  def test_deep_copy
    object_a = [Object.new, {:a => Object.new, :b => [Object.new, Object.new], :c => {:d => Object.new}}, [Object.new, Object.new]]
    object_b = @protector.send(:deep_copy, object_a)
    
    
    assert_not_equal object_a[0].object_id, object_b[0].object_id
    assert_not_equal object_a[1].object_id, object_b[1].object_id
    assert_not_equal object_a[2].object_id, object_b[2].object_id
    
    assert_not_equal object_a[1][:a].object_id, object_b[1][:a].object_id
    assert_not_equal object_a[1][:b].object_id, object_b[1][:b].object_id
    assert_not_equal object_a[1][:b][0].object_id, object_b[1][:b][0].object_id
    assert_not_equal object_a[1][:b][1].object_id, object_b[1][:b][1].object_id
    assert_not_equal object_a[1][:c].object_id, object_b[1][:c].object_id
    assert_not_equal object_a[1][:c][:d].object_id, object_b[1][:c][:d].object_id
    
    assert_not_equal object_a[2][0].object_id, object_b[2][0].object_id
    assert_not_equal object_a[2][1].object_id, object_b[2][1].object_id
  end
  
  def test_action_matches
    assert  @protector.send(:action_matches?, :only, ["blah", "bleck"], "blah")
    assert  @protector.send(:action_matches?, :only, ["blah", "bleck"], "bleck")
    assert !@protector.send(:action_matches?, :only, ["blah", "bleck"], "not")
    
    assert !@protector.send(:action_matches?, :except, ["blah", "bleck"], "blah")
    assert !@protector.send(:action_matches?, :except, ["blah", "bleck"], "bleck")
    assert  @protector.send(:action_matches?, :except, ["blah", "bleck"], "not")
    
    assert_raises(ArgumentError){ @protector.send(:action_matches?, :bad_scope, ["blah", "bleck"], "not") }
  end
  
  def test_do_param_accessible
    
    accessible_params = { :account_id => nil,
                          :user_id => nil }
    params            = { :account_id => 123,
                          :user_id => 456,
                          :profile_id => 789 }
    expected_results  = { :account_id => 123,
                          :user_id => 456 }
    assert_equal expected_results, @protector.send(:filter_params, accessible_params, params, ParamProtected::WHITELIST)
    
    accessible_params = { :account_id => nil,
                          :user => nil }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro" },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro"} }
    assert_equal expected_results, @protector.send(:filter_params, accessible_params, params, ParamProtected::WHITELIST)
    
    accessible_params = { :account_id => nil,
                          :user => {:first_name => nil, :last_name => nil} }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro", :middle_name => "james" },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro"} }
    assert_equal expected_results, @protector.send(:filter_params, accessible_params, params, ParamProtected::WHITELIST)
    
    accessible_params = { :account_id => nil,
                          :user => {:name => {:first => nil, :last => nil}} }
    params            = { :account_id => 123,
                          :user => { :city => "Austin",
                                     :name => {:first => "christopher", :last => "bottaro", :middle => "james"} },
                          :profile_ids => [789, 987] }
    expected_results  = { :account_id => 123,
                          :user => { :name => {:first => "christopher", :last => "bottaro"} } }
    assert_equal expected_results, @protector.send(:filter_params, accessible_params, params, ParamProtected::WHITELIST)
  end
  
  def test_do_param_protected
    
    protected_params  = { :account_id => nil,
                          :user => nil }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro" },
                          :profile_ids => [789, 987] }
    expected_results  = { :profile_ids => [789, 987] }
    assert_equal expected_results, @protector.send(:filter_params, protected_params, params, ParamProtected::BLACKLIST)
    
    protected_params  = { :account_id => nil,
                          :user => {:middle_name => nil} }
    params            = { :account_id => 123,
                          :user => { :first_name => "christopher", :last_name => "bottaro", :middle_name => "james" },
                          :profile_ids => [789, 987] }
    expected_results  = { :user => {:first_name => "christopher", :last_name => "bottaro"},
                          :profile_ids => [789, 987] }
    assert_equal expected_results, @protector.send(:filter_params, protected_params, params, ParamProtected::BLACKLIST)
    
    protected_params  = { :account_id => nil,
                          :user => {:name => {:middle => nil}} }
    params            = { :account_id => 123,
                          :user => { :city => "Austin",
                                     :name => {:first => "christopher", :last => "bottaro", :middle => "james"} },
                          :profile_ids => [789, 987] }
    expected_results  = { :profile_ids => [789, 987],
                          :user => { :city => "Austin",
                          :name => {:first => "christopher", :last => "bottaro"} } }
    assert_equal expected_results, @protector.send(:filter_params, protected_params, params, ParamProtected::BLACKLIST)
  end
  
end
