# paramProtected

module Cjbottaro

  module ParamProtected

    def self.extended(klass)
      klass.class_eval do
        include InstanceMethods
      end
    end
    
    def param_protected(params, actions = nil)
      Helpers.init_storage(self)
      params  = Helpers.normalize_params(params)
      actions = Helpers.normalize_actions(actions)
      self.pp_protected << [params, actions]
      skip_before_filter    :do_param_protected
      prepend_before_filter :do_param_protected
    end
    
    def param_accessible(params, actions = nil)
      Helpers.init_storage(self)
      params  = Helpers.normalize_params(params)
      actions = Helpers.normalize_actions(actions)
      self.pp_accessible << [params, actions]
      skip_before_filter    :do_param_accessible
      prepend_before_filter :do_param_accessible
    end
    
    module InstanceMethods
    
      def do_param_protected
        self.class.pp_protected.each do |protected_params, actions|
          scope, actions = actions.first, actions[1..-1]
          Helpers.do_param_protected(protected_params, self.params) \
            if Helpers.action_matches?(scope, actions, self.action_name)
        end
      end
      
      def do_param_accessible
        self.class.pp_accessible.each do |accessible_params, actions|
          scope, actions = actions.first, actions[1..-1]
          Helpers.do_param_accessible(accessible_params, self.params) \
            if Helpers.action_matches?(scope, actions, self.action_name)
        end
      end
      
    end
    
    module Helpers
      
      def self.init_storage(klass)
        class << klass
          attr_accessor :pp_protected, :pp_accessible
        end
        klass.pp_protected  = [] if klass.pp_protected.nil?
        klass.pp_accessible = [] if klass.pp_accessible.nil?
      end
      
      def self.normalize_params(params, params_out = {})
        if params.instance_of?(Array)
          params.each{ |param| normalize_params(param, params_out) }
        elsif params.instance_of?(Hash)
          params.each do |k, v|
            k = k.to_s
            params_out[k] = {}
            normalize_params(v, params_out[k])
          end
        else
          params_out[params.to_s] = nil
        end
        params_out
      end
      
      def self.normalize_actions(actions)
        error_message = "invalid actions, use :only => ..., :except => ..., or nil"
        return [:except, nil] if actions.blank?
        raise ArgumentError, error_message unless actions.instance_of?(Hash)
        raise ArgumentError, error_message unless actions.length == 1
        raise ArgumentError, error_message unless [:only, :except].include?(actions.keys.first)
        
        scope, actions = actions.keys.first, actions.values.first
        actions = [actions] unless actions.instance_of?(Array)
        actions = actions.collect{ |action| action.to_s }
        [scope, *actions]
      end
      
      def self.action_matches?(scope, valid_actions, action_name)
        if scope == :only
          valid_actions.include?(action_name)
        elsif scope == :except
          !valid_actions.include?(action_name)
        else
          raise ArgumentError, "unexpected scope (#{scope}), expected :only or :except"
        end
      end
      
      def self.do_param_protected(protected_params, params)
        return unless params.kind_of?(Hash)
        return if protected_params.nil?
        params.delete_if{ |k, v| protected_params.has_key?(k) and protected_params[k].nil? }
        params.each{ |k, v| do_param_protected(protected_params[k], v) }
        params
      end
      
      def self.do_param_accessible(accessible_params, params)
        return unless params.kind_of?(Hash)
        return if accessible_params.nil?
        params.delete_if{ |k, v| !accessible_params.has_key?(k) }
        params.each{ |k, v| do_param_accessible(accessible_params[k], v) }
        params
      end
      
    end
    
  end
  
end