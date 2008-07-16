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
        params_to_kill = Helpers.params_to_live_or_kill(self.class.pp_protected, action_name.to_s)
        params_by_path = Helpers.params_by_path(params)
        params_to_kill.each do |param|
          next unless params_by_path.has_key?(param)
          params_by_path[param].each { |h, v| h.delete(v) }
        end
      end
      
      def do_param_accessible
        params_to_live = Helpers.params_to_live_or_kill(self.class.pp_accessible, action_name.to_s)
        return if params_to_live.blank?
        params_by_path = Helpers.params_by_path(params)
        params_by_path.each do |path, hash|
          next if params_to_live.include?(path)
          hash.each { |h, v| h.delete(v) }
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
      
      def self.normalize_params(params)
        params = [params] unless params.instance_of?(Array)
        params.collect{ |param| param.to_s }
      end
      
      def self.normalize_actions(actions)
        return [:except] if actions.blank?
        scope, actions = actions.keys.first, actions.values.first
        actions = [actions] unless actions.instance_of?(Array)
        actions = actions.collect{ |action| action.to_s }
        [scope, *actions]
      end
      
      # specs will something like...
      # [[param1, param2], [:only, action1, action2]
      #  [param2, param3], [:except, action3, action4]]
      def self.params_to_live_or_kill(specs, action)
        specs.inject([]) do |memo, params_actions|
          params, actions = params_actions
          scope = actions.first # actions is a reference to a part of pp_protected or pp_accessible, so we don't want to alter it
          actions = actions[1..-1]
          memo += params if scope == :only and actions.include?(action)
          memo += params if scope == :except and !actions.include?(action)
          memo
        end
      end

      # Takes a params hash and returns a hash where the keys are an xpath like string and the values are the
      # information needed to remove the entry from the inputted params hash.
      # Examples:
      #  params = { :user => {:first => 'calia', :last => 'rose' } }
      #  params_by_xpathy(params) => { 'user' => [[params, :user]],
      #                                'user/first' => [[params[:user], :first]],
      #                                'user/last'  => [[params[:user], :last]] }
      # Notice the values are arrays of doubles.  That's so we can properly filter on params that are arrays, like so:
      #  params = { :users => [ {:first => 'calia', :last => 'rose'},
      #                         {:first => 'coco',  :last => 'rae' } ] }
      #  params_by_xpathy(params) => { 'users' => [[params, :user]],
      #                                'users/first' => [[params[:user][0], :first], [params[:user][1], :first]],
      #                                'users/last'  => [[params[:user][0], :last ], [params[:user][0], :last ]] }
      # Now if we want to protect parameter 'users/first', we can simply do...
      #  params_by_xpathy(params)['users/first'].each { |h, v| h.delete(v) }      
      def self.params_by_path(node, path_so_far = '', result = {})
        node.each do |k, v|
          path = path_so_far.blank? ? k.to_s : path_so_far + "/#{k}"
          result[path] ||= []
          result[path] << [node, k]
          if v.is_a?(Hash)
            params_by_path(v, path, result)
          elsif v.is_a?(Array)
            v.each{ |e| params_by_path(e, path, result)  }
          end
        end
        return result
      end
      
    end

  end

end