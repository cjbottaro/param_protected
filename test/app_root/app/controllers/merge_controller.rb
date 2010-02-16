class MergeController < ApplicationController
  param_accessible :a, :only => :first
  param_accessible :b
  param_accessible({ :h => :c}, :except => :first)
  param_accessible :h => :b
  

  def first; end

  def second; end
end
