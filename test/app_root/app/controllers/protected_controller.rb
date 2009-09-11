class ProtectedController < ApplicationController
  param_protected :a
  
  def an_action; end
  
  param_protected :b, :only => :only_one_action
  def only_one_action; end
  
  param_protected :c, :except => :except_one_action
  def except_one_action; end
  
  param_protected [:d, :e], :only => :params_as_array
  def params_as_array;end
  
  param_protected :f, :only => [:only_multiple_actions1, :only_multiple_actions2]
  def only_multiple_actions1; end
  def only_multiple_actions2; end
  
  param_protected :g, :except => [:except_multiple_actions1, :except_multiple_actions2]
  def except_multiple_actions1; end
  def except_multiple_actions2; end
  
  param_protected( { :h => :a }, :only => :nested_single )
  def nested_single; end
  
  param_protected( { :h => [:a, :b] }, :only => :nested_multiple )
  def nested_multiple; end
  
end