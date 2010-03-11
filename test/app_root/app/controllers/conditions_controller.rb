class ConditionsController < ApplicationController
  param_accessible :a, :if => :something?
  param_accessible :b, :unless => false
  param_protected  :b, :if => :first_action?
  param_accessible :c, :if => lambda { |controller| controller.instance_eval { first_action? } }
  
  def first; end
  
  def second; end

  protected
  
  def something?
    true
  end

  def first_action?
    action_name == 'first'
  end
  
end
