module Themis
  module ActiveRecordExtension
    # Adds new validation to ActiveRecord model
    class ValidationAttacher

      def initialize(model, validation_module_and_options, block)
        @model_class = model
        options = validation_module_and_options.extract_options!

        @validation_module = validation_module_and_options.first
        @validation_name   = options[:as].try(:to_sym)
        @is_default        = options[:default] || false
        @nested            = options[:nested]
        @block = block
      end

      def attach!
        preinitialize_model_class!
        validate!
        @model_class.themis_validations << AttachedValidation.new(@validation_name, :nested => @nested)
        add_conditional_validators!
        add_after_initialize_hook! if @is_default
      end

      def add_conditional_validators!
        # Define local variable to have ability to pass its value to lambda
        validation_name = @validation_name

        condition = lambda { |obj| obj.themis_validation == validation_name }
        model_proxy = ModelProxy.new(@model_class, condition)
        if @validation_module
          @validation_module.validators.each do |validator|
            model_proxy.send(validator.name, *validator.args)
          end
        end
        @block.call(model_proxy) if @block
      end
      private :add_conditional_validators!

      def add_after_initialize_hook!
        # Define local variable to have ability to pass its value to proc
        validation_name = @validation_name

        @model_class.themis_default_validation = validation_name
        @model_class.after_initialize { @themis_validation = validation_name }
      end
      private :add_after_initialize_hook!


      def preinitialize_model_class!
        @model_class.themis_validations        ||= []
        @model_class.themis_default_validation ||= nil
      end
      private :preinitialize_model_class!

      def validate!
        unless @validation_name
          raise(ArgumentError.new("option `:as` is required for `.use_validation` method"))
        end

        if !@validation_module && !@block
          raise ArgumentError.new("Validation module or block must be given to `.use_validation` method")
        end

        if @model_class.themis_validations.map(&:name).include?(@validation_name)
          raise ArgumentError.new("validation `#{@validation_name.inspect}` already defined")
        end

        if @is_default && @model_class.themis_default_validation
          msg = "`#{@model_class.themis_default_validation.inspect}` " \
                "validation is already used as default"
          raise ArgumentError.new(msg)
        end
      end
      private :validate!

    end  # class ValidationAttacher
  end  # module ActiveRecordExtension
end  # module Themis
