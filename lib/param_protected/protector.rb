module ParamProtected
  class Protector
  
    def self.instance(controller)
      unless controller.respond_to?(:pp_protector)
        controller.class_eval{ @pp_protector = Protector.new }
        controller.singleton_class.class_eval { attr_reader :pp_protector }
      end
      controller.pp_protector
    end
    
    def initialize
      @protections = []
    end

    def initialize_copy(copy)
      copy.instance_variable_set(:@protections, deep_copy(@protections))
    end
    
    def declare_protection(params, options, exclusivity)
      params  = normalize_params(params)
      actions, condition = normalize_options(options)
      @protections << [params, actions, condition, exclusivity]
    end
    
    def protect(controller, controller_params, action_name)
      deep_copy(controller_params).tap do |params|
        protections_for_action(controller, action_name).each do |exclusivity, protected_params|
          filter_params(protected_params, params, exclusivity) unless protected_params.empty?
        end
      end
    end
    
  private

    def protections_for_action(controller, action_name)
      @protections.select do |protected_params, actions, condition, exclusivity|
        action_matches?(actions[0], actions[1..-1], action_name) && condition_applies?(controller, condition)
      end.inject({ WHITELIST => { }, BLACKLIST => { } }) do |result, (protected_params, actions, condition, exclusivity)|
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
          k = normalize_key(k)
          params_out[k] = {}
          normalize_params(v, params_out[k])
        end
      else
        params_out[normalize_key(params)] = nil
      end
      params_out
    end

    def normalize_key(k)
      if k.is_a?(Regexp)
        k
      else
        k.to_s
      end
    end
    
    # When specifying which actions param protection apply to, we allow a format like this...
    #   :only => [:action1, :action2]
    # This method normalizes that to...
    #   [:only, "action1", "action2"]
    def normalize_options(options)
      error_message = "invalid options, use :only or :except, :if or :unless"
      return [[:except, nil], [:if, true]] if options.blank?

      raise ArgumentError, error_message unless options.instance_of?(Hash)

      scope = [:only, :except] & options.keys
      condition = [:if, :unless] & options.keys

      raise ArgumentError, error_message unless (options.keys - [:only, :except, :if, :unless]).empty?
      raise ArgumentError, error_message if scope.size > 1 || condition.size > 1

      scope = scope.first || :except
      actions = options[scope]
      actions = [actions] unless actions.instance_of?(Array)
      actions = actions.collect{ |action| action.try(:to_s) }

      condition = condition.first || :if
      
      if options.has_key?(condition)
        condition_value = options[condition]
      else
        condition_value = true
      end
      
      [[scope, *actions], [condition, condition_value]]
    end
    
    # When #dup just isn't enough... :P
    def deep_copy(object)
      try_to_clone(object).tap do |new_object|
        case new_object
        when Hash
          new_object.each{ |k, v| new_object[k] = deep_copy(v) }
        when Array
          new_object.replace(new_object.collect{ |item| deep_copy(item) })
        end
      end
    end
    
    # Some objects are not dupable... like TrueClass, FalseClass and NilClass.
    def try_to_clone(object)
      object.clone
    rescue TypeError
      object
    end

    def condition_applies?(controller, condition)
      result = case condition[1]
               when Proc
                 condition[1].call(controller)
               when Symbol, String
                 controller.send(condition[1])
               else
                 condition[1]
               end

      if condition[0] == :unless
        not result
      else
        result
      end
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
        params.delete_if{ |k, v| key_exists?(protected_params, k) and find_by_key(protected_params, k).nil? }
      elsif exclusivity == WHITELIST
        params.delete_if{ |k, v| !key_exists?(protected_params, k) }
      else
        raise ArgumentError, "unexpected exclusivity: #{exclusivity}"
      end
      params.each{ |k, v| filter_params(find_by_key(protected_params, k), v, exclusivity) }
      params
    end

    def find_by_key(protected_params, key)
      protected_params.detect do |k,v|
        key_matches?(k, key)
      end.try(:last)
    end
    
    def key_exists?(protected_params, key)
      protected_params.any? do |k,v|
        key_matches?(k, key)
      end
    end

    def key_matches?(k, key)
      if k.is_a? Regexp
        key.to_s =~ k
      else
        key.to_s == k.to_s
      end
    end

  end
end
