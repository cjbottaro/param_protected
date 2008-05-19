# paramProtected

module Cjbottaro

  module ParamProtected

    def self.included(base)
      base.extend BaseClassMethods
    end

    module BaseClassMethods

      attr_accessor :_pp_protected_map, :_pp_accessible_map
      
      def param_accessible(param_list, actions = nil)
        self._pp_add_to_map(param_list, actions, :accessible)
      end

      def param_protected(param_list, actions = nil)
        self._pp_add_to_map(param_list, actions, :protected)
      end
      
      protected
      
      # Build the protected/accessible maps for the controller (self).
      # Ex:
      #  param_protected [:user_id, :client_id], :only => :some_action
      #  param_protected :account_id, :only => :another_action
      # would result in a _pp_protected_map of
      #  { :some_action    => [:user_id, :client_id],
      #    :another_action => [:account_id] }
      def _pp_add_to_map(params, actions, which_map)
        PrivateMethods.sanity_check_arguments(params, actions)
        include Cjbottaro::ParamProtected::InstanceMethods
        self._pp_init_maps
        map = which_map == :accessible ? self._pp_accessible_map : self._pp_protected_map
        params = PrivateMethods.normalize_to_array(params)
        actions = self._pp_get_actions(actions)
        actions.each do |action|
          map[action] ||= []
          map[action] += params
        end
        
        # add the actual protection method as a before filter
        self.skip_before_filter    :_pp_do_param_filter # this is for the people who call protect_param more than once for a single controller
        self.prepend_before_filter :_pp_do_param_filter
      end
      
      # Initialize the protected/accessible maps to {} if they don't exist yet.
      def _pp_init_maps
        self._pp_protected_map  = {} if self._pp_protected_map.blank?
        self._pp_accessible_map = {} if self._pp_accessible_map.blank?
      end
      
      # Given an action hash (second argument to param_protected), figure out which actions we mean.
      # So if we have a controller (self) with three actions, :action1, :action2, :action3 ...
      #  _pp_get_actions :only => :action1                # returns [:action1]
      #  _pp_get_actions :except => :action1              # returns [:action2, :action3]
      #  _pp_get_actions :except => [:action2, :action3]  # returns [:action1]
      def _pp_get_actions(actions)
        action_methods = PrivateMethods.normalize_to_array(Set.new(public_instance_methods - hidden_actions))
        
        if actions.blank?
          actions = action_methods
        elsif actions.has_key?(:only)
          actions = PrivateMethods.normalize_to_array(actions[:only])
          actions = action_methods.to_set & actions.to_set
        elsif actions.has_key?(:except)
          actions = PrivateMethods.normalize_to_array(actions[:except])
          actions = action_methods.to_set - actions.to_set
        else
          raise RuntimeError, "second argument to param_protected or param_accessible should be hash with single key - :only or :except"
        end
        
        return actions
      end
      
    end

    module ClassMethods
    end

    module InstanceMethods
      
      protected
      
      # This is the method that gets registered to the controller via prepend_before_filter when you call
      # either param_protected or param_accessible.  It will eventually call methods (see below) that will
      # filter an action's params.
      def _pp_do_param_filter
        killed_params1, killed_params2 = {}, {}
        action_name = self.action_name.to_s
        param_map   = PrivateMethods.params_by_xpathy(params)
        killed_params1 = self._pp_do_accessible_filter(action_name, param_map) if self.class._pp_accessible_map.has_key?(action_name)
        killed_params2 = self._pp_do_protected_filter(action_name, param_map)  if self.class._pp_protected_map.has_key?(action_name)
        logger.info "  Parameters protected: " + killed_params1.merge(killed_params2).inspect
      end
      
      # Filter an action's params by looking at the accessible map (which was made by calls to param_accessible).
      def _pp_do_accessible_filter(action_name, params_by_xpathy)
        killed_params = {}
        params_to_access = self.class._pp_accessible_map[action_name]
        params_by_xpathy.each do |param_path, delete_list|
          next if params_to_access.include?(param_path)
          # Consider param_accessible 'user/fname'.  params[:user][:fname] will be deleted because params[:user] will be
          # deleted because 'user' is not on the accessible list.  That's why we have the 'unless h[k].kind_of?(Hash).
          delete_list.each { |h, k| killed_params[k] = h.delete(k) unless h[k].kind_of?(Hash) }
        end
        return killed_params
      end
      
      # Filter an action's params by looking at the protected map (which was made by calls to param_protected).
      def _pp_do_protected_filter(action_name, params_by_xpathy)
        killed_params = {}
        params_to_protect = self.class._pp_protected_map[action_name]
        params_by_xpathy.each do |param_path, delete_list|
          next unless params_to_protect.include?(param_path)
          delete_list.each { |h, k| killed_params[k] = h.delete(k) }
        end
        return killed_params
      end
      
    end

    module PrivateMethods

      # Takes a scalar or collection of scalars and normalizes it an array of Strings.
      def self.normalize_to_array(x)
        if x.respond_to?(:collect)
          return x.collect{ |y| y.to_s }
        else
          return [ x.to_s ]
        end
      end
      
      # Checks that the arguments to param_protected/param_accessible make sense.
      def self.sanity_check_arguments(params, actions)
        errmsg = "second argument must be nil or a hash containing a single key:  :only or :except."
        if actions.blank?
          nil # noop
        elsif !actions.instance_of?(Hash)
          raise RuntimeError.new(errmsg)
        elsif !actions.has_key?(:only) && !actions.has_key?(:except)
          raise RuntimeError.new(errmsg)
        elsif  actions.has_key?(:only) &&  actions.has_key?(:except)
          raise RuntimeError.new(errmsg)
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
      def self.params_by_xpathy(node, path_so_far = '', result = {})
        node.each do |k, v|
          path = path_so_far.blank? ? k.to_s : path_so_far + "/#{k}"
          result[path] ||= []
          result[path] << [node, k]
          if v.is_a?(Hash)
            params_by_xpathy(v, path, result)
          elsif v.is_a?(Array)
            v.each{ |e| params_by_xpathy(e, path, result)  }
          end
        end
        return result
      end
      
    end
    
  end

end