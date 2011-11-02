module ParamProtected
  module ControllerModifications
    extend ActiveSupport::Concern

    included do
      alias_method_chain :params, :protection
    end

    module ClassMethods
      def _protector
        @_protector ||= Protector.new
      end

      def _protector=(value)
        @_protector = value
      end

      def param_protected(params, actions = nil)
        _protector.declare_protection(params, actions, BLACKLIST)
      end

      def param_accessible(params, actions = nil)
        _protector.declare_protection(params, actions, WHITELIST)
      end

      def inherited(m)
        m._protector = _protector.dup
        super
      end
    end

    module InstanceMethods
      def _protector
        self.class._protector
      end

      def params_with_protection
        return params_without_protection if action_name.blank?
        @params_with_protection ||= _protector.protect(self, params_without_protection, action_name)
      end
    end
  end
end
