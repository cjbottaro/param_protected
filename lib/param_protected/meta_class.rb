class Object
  unless method_defined?(:meta_class)
    def meta_class
      (class << self; self; end)
    end
  end
  
  unless method_defined?(:meta_eval)
    def meta_eval(&block)
      meta_class.instance_eval(&block)
    end
  end
end