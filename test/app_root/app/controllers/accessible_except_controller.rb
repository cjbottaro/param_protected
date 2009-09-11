class AccessibleExceptController < ApplicationController
  param_accessible :a, :except => :first
  
  def first; end
  
  def second; end
end
