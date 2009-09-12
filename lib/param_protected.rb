require "param_protected/meta_class"
require "param_protected/constants"
require "param_protected/protector"
require "param_protected/controller_modifications"

ActionController::Base.extend(ParamProtected::ControllerModifications)