class AccessibleOnlyController < ApplicationController
  param_accessible :a, :only => :first

  def first; end

  def second; end
end
