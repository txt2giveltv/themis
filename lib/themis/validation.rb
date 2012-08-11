module Themis
  module Validation
    extend ActiveSupport::Autoload

    autoload :Validator

    def validators
      @validators ||= []
    end

    # Copy {Validator validators} when module is included.
    # @param [Module] base another validation module extend with {Themis::Validation}.
    def included(base)
      if base.instance_of?(Module) && base.respond_to?(:validators)
        base.validators.concat(validators)
      elsif base.ancestors.include? ::ActiveRecord::Base
        apply_to_model!(base)
      else
        raise "Validation module `#{self.inspect}` can be included only in another validation module or in ActiveRecord model"
      end
    end

    def apply_to_model!(model_class)
      validators.each do |validator|
        method, args = validator.name, validator.args
        model_class.send(method, *args)
      end
    end

    def method_missing(name, *args)
      if name.to_s =~ /\Avalidates/
        self.validators << Validator.new(name, args)
      else
        super(name, *args)
      end
    end
    private :method_missing

  end
end
