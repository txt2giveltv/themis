module Themis
  # It's mean to extend other modules to make them be validation modules
  # Consider it as "parent module" for all validation modules.
  #
  # @example define UserValidation
  #
  #   module UserValidation
  #     extend Themis::Validation
  #
  #     validates :email   , :presence => true
  #     validates :nickname, :presence => true
  #   end
  module Validation
    extend ActiveSupport::Autoload

    autoload :Validator

    # Array {Validator validators} defined in module.
    # @return [Array<Validator>] array of module's validators
    def validators
      @validators ||= []
    end

    # When included in another module: copy {Validator validators} to another module.
    # When included in AcitveRecord model: define validators on model.
    # @param [Module, ActiveRecord::Base] base another validation module or ActiveRecord model.
    def included(base)
      if base.instance_of?(Module) && base.respond_to?(:validators)
        base.validators.concat(validators)
      elsif base.ancestors.include? ::ActiveRecord::Base
        apply_to_model!(base)
      else
        raise "Validation module `#{self.inspect}` can be included only in another validation module or in ActiveRecord model"
      end
    end

    # Save all calls of validation methods as array of validators
    def method_missing(method_name, *args)
      if method_name.to_s =~ /\Avalidates/
        self.validators << Themis::Validation::Validator.new(method_name, args)
      else
        super
      end
    end
    private :method_missing

    # Add validators to model
    # @param [AcitveRecord::Base] model_class
    def apply_to_model!(model_class)
      validators.each do |validator|
        method, args = validator.name, validator.args
        model_class.send(method, *args)
      end
    end
    private :apply_to_model!

  end  # module Validation
end  # module Themis
