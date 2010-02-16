module ParamProtected
  module ControllerModifications
    
    def self.extended(action_controller)
      action_controller.class_eval do
        extend  ClassMethods
        metaclass.alias_method_chain :inherited, :protector
        include InstanceMethods
        alias_method_chain :params, :protection
      end
    end
    
    module ClassMethods
      
      def param_protected(params, actions = nil)
        Protector.instance(self).declare_protection(params, actions, BLACKLIST)
      end
      
      def param_accessible(params, actions = nil)
        Protector.instance(self).declare_protection(params, actions, WHITELIST)
      end

      def inherited_with_protector(controller)
        inherited_without_protector(controller)

        if defined? @pp_protector
          controller.instance_variable_set :@pp_protector, @pp_protector.dup
          controller.class_eval { attr_reader :pp_protector }
        end
        
      end
      
    end
    
    module InstanceMethods
      
      def params_with_protection
        
        # #params is called internally by ActionController::Base a few times before an action is dispatched,
        # thus we can't filter and cache it right off the bat.  We have to wait for #action_name to be present
        # to know that we're really in an action and @_params actually contains something.  Then we can filter
        # and cache it.
        
        if action_name.blank?
          params_without_protection
        elsif @params_protected
          @params_protected
        else
          @params_protected = Protector.instance(self.class).protect(params_without_protection, action_name)
        end
        
      end
      
    end
    
  end
end