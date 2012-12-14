module Themis
  module AR
    # Encapsulates implementation of
    # {AR::BaseExtension::ClassMethods#has_validation has_validation} method.
    class HasValidationMethod
      # @param [ActiveRecord::Base] model_class
      # @param [Symbol] names names of validation sets
      # @param [Module, nil] validation_module
      # @param [Hash, nil] options
      # @param [Proc, nil] block
      def initialize(model_class, names, validation_module, options, block)
        @model_class = model_class
        @names       = names
        @module      = validation_module
        @default     = options[:default] || false
        @nested      = options[:nested]
        @block       = block
      end

      # Execute the method.
      def execute!
        preinitialize_model_class!
        validate!
        register_validation_sets!
        add_conditional_validators!
        add_after_initialize_hook! if @default
        add_before_validation_hook!
      end


      # Unless themis_validation_sets and themis_default_validation
      # is set, then set them. This is necessary to do in every inheritor
      # of ActiveRecord::Base to avoid overriding values for the entire
      # ActiveRecord::Base hierarchy.
      def preinitialize_model_class!
        @model_class.themis_validation_sets    ||= {}
        @model_class.themis_default_validation ||= nil
      end
      private :preinitialize_model_class!


      # Add {ValidationSet validation sets} to themis_validation_sets collection.
      def register_validation_sets!
        @names.each do |name|
          @model_class.themis_validation_sets[name] ||= ValidationSet.new(
            :name    => name,
            :module  => @module,
            :default => @default,
            :nested  => @nested,
            :block   => @block
          )
        end
      end
      private :register_validation_sets!

      # Add {ValidationSet validation set} to themis_validation_sets collection.
      #def register_validation_set(name)
      #end
      #private :register_validation_set!


      # Add conditional validation to ActiveRecord model.
      def add_conditional_validators!
        # Define local variable to have ability to pass its value to lambda
        validation_names = @names

        condition   = lambda { |obj| obj.themis_validation.in?(validation_names) }
        model_proxy = ModelProxy.new(@model_class, condition)

        if @module
          @module.validators.each do |validator|
            model_proxy.send(validator.name, *validator.args)
          end
        end
        @block.call(model_proxy) if @block
      end
      private :add_conditional_validators!


      # Add after_initialize hook to set default validation.
      def add_after_initialize_hook!
        if @names.size > 1
          raise "Can not set default to multiple validations"
        end

        # Define local variable to have ability to pass its value to proc
        validation_name = @names.first
        @model_class.themis_default_validation = validation_name
        @model_class.after_initialize { use_validation(validation_name) }
      end
      private :add_after_initialize_hook!

      # Add before_validation hook to make all nested models use same
      # validation set.
      def add_before_validation_hook!
        @model_class.before_validation do
          themis_validation ? use_validation(themis_validation) : use_no_validation
        end
      end
      private :add_before_validation_hook!

      # Run validation to be sure that minimum of necessary parameters were passed.
      def validate!
        if @default && @model_class.themis_default_validation
          warn "WARNING: validation `#{@model_class.themis_default_validation}` " \
               "is already used as default on #{@model_class}"
        end
      end
      private :validate!

    end  # class HasValidationMethod
  end  # module AR
end  # module Themis
