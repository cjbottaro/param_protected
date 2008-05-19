# Include hook code here
require 'param_protected'

ActionController::Base.send(:include, Cjbottaro::ParamProtected)