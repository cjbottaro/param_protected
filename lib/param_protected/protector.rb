module ParamProtected
  class Protector
  
    def self.instance(controller)
      unless controller.respond_to?(:pp_protector)
        controller.class_eval{ @pp_protector = Protector.new }
        controller.meta_eval { attr_reader :pp_protector }
      end
      controller.pp_protector
    end
    
    def initialize
      @protections = []
    end
    
    def declare_protection(params, actions, exclusivity)
      params  = normalize_params(params)
      actions = normalize_actions(actions)
      @protections << [params, actions, exclusivity]
    end
    
    def protect(controller_params, action_name)
      returning(deep_copy(controller_params)) do |params|
        @protections.each do |protected_params, actions, exclusivity|
          scope, actions = actions.first, actions[1..-1] # Careful not to modify the actions array in place.
          next unless action_matches?(scope, actions, action_name)
          filter_params(protected_params, params, exclusivity)
        end
      end
    end
    
  private
    
    # When specifying params to protect, we allow a combination of arrays and hashes much like how
    # ActiveRecord::Base#find's :include options works.  This method normalizes that into just nested hashes,
    # stringifying the keys and setting all values to nil.  This format is easier/faster to work with when 
    # filtering the controller params.
    # Example...
    #   [:a, {:b => [:c, :d]}]
    # to
    #   {"a"=>nil, "b"=>{"c"=>nil, "d"=>nil}}
    def normalize_params(params, params_out = {})
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
    
    # When specifying which actions param protection apply to, we allow a format like this...
    #   :only => [:action1, :action2]
    # This method normalizes that to...
    #   [:only, "action1", "action2"]
    def normalize_actions(actions)
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
    
    # When #dup just isn't enough... :P
    def deep_copy(object)
      returning(try_to_dup(object)) do |new_object|
        case new_object
        when Hash
          new_object.each{ |k, v| new_object[k] = deep_copy(v) }
        when Array
          new_object.replace(new_object.collect{ |item| deep_copy(item) })
        end
      end
    end
    
    # Some objects are not dupable... like TrueClass, FalseClass and NilClass.
    def try_to_dup(object)
      object.dup
    rescue TypeError
      object
    end
    
    def action_matches?(scope, actions, action_name)
      if action_name.blank?
        false
      elsif scope == :only
        actions.include?(action_name)
      elsif scope == :except
        !actions.include?(action_name)
      else
        raise ArgumentError, "unexpected scope (#{scope}), expected :only or :except"
      end
    end
    
    def filter_params(protected_params, params, exclusivity)
      return unless params.kind_of?(Hash)
      return if protected_params.nil?
      if exclusivity == BLACKLIST
        params.delete_if{ |k, v| protected_params.has_key?(k) and protected_params[k].nil? }
      elsif exclusivity == WHITELIST
        params.delete_if{ |k, v| !protected_params.has_key?(k) }
      else
        raise ArgumentError, "unexpected exclusivity: #{exclusivity}"
      end
      params.each{ |k, v| filter_params(protected_params[k], v, exclusivity) }
      params
    end
    
  end
end