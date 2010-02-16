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
        protections_for_action(action_name).each do |exclusivity, protected_params|
          filter_params(protected_params, params, exclusivity) unless protected_params.empty?
        end
      end
    end
    
  private

    def protections_for_action(action_name)
      @protections_for_action ||= { }

      @protections_for_action[action_name] ||= @protections.select do |protected_params, actions, exclusivity|
        action_matches?(actions[0], actions[1..-1], action_name)
      end.inject({ WHITELIST => { }, BLACKLIST => { } }) do |result, (protected_params, action_name, exclusivity)|
        merge_protections(result[exclusivity], protected_params)
        result
      end
    end

    # Merge protections for the same params into one so as to allow extension of them 
    # in inheriting controllers.
    # 
    # Mutating the first argument is okay since this method is used within inject only.
    # 
    # Example:
    # merge_protections({ :foo => { :qux => nil }, :bar => { :baz => nil, :qux => nil } },
    #                   { :foo => { :baz => nil, :qux => { :foo => nil } } })
    # => 
    #
    # { :foo => { :baz => nil, :qux => { :foo => nil } }, :bar => { :baz =>nil, :qux => nil } }
    def merge_protections(protections, protected_params)
      protected_params.each do |k,v|
        if protections[k].is_a?(Hash)
          merge_protections(protections[k], v) if v
        else
          protections[k] = v
        end
      end

      protections
    end
    
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