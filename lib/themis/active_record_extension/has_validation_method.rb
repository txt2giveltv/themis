module Themis
  module ActiveRecordExtension
    class HasValidationMethod

      def initialize(model_class, name, validation_module, options, block)
        @model_class = model_class
        @name        = name.to_sym
        @module      = validation_module
        @default     = options[:default] || false
        @nested      = options[:nested]
        @block       = block
      end

      def execute!
        preinitialize_model_class!
        validate!
        register_validation_set!
        add_conditional_validators!
        add_after_initialize_hook! if @default
      end



      def preinitialize_model_class!
        @model_class.themis_validation_sets        ||= {}
        @model_class.themis_default_validation ||= nil
      end
      private :preinitialize_model_class!

      def register_validation_set!
        @model_class.themis_validation_sets[@name] = ValidationSet.new(
          :name    => @name,
          :module  => @module,
          :default => @default,
          :nested  => @nested,
          :block   => @block
        )
      end

      def add_conditional_validators!
        # Define local variable to have ability to pass its value to lambda
        validation_name = @name

        condition = lambda { |obj| obj.themis_validation == validation_name }
        model_proxy = ModelProxy.new(@model_class, condition)
        if @module
          @module.validators.each do |validator|
            model_proxy.send(validator.name, *validator.args)
          end
        end
        @block.call(model_proxy) if @block
      end
      private :add_conditional_validators!

      def add_after_initialize_hook!
        # Define local variable to have ability to pass its value to proc
        validation_name = @name

        @model_class.themis_default_validation = validation_name
        @model_class.after_initialize { @themis_validation = validation_name }
      end
      private :add_after_initialize_hook!



      def validate!
        if !@module && !@block
          raise ArgumentError.new("Validation module or block must be given to `.use_validation` method")
        end

        if @model_class.has_themis_validation?(@name)
          raise ArgumentError.new("validation `#{@name.inspect}` already defined")
        end

        if @default && @model_class.themis_default_validation
          msg = "`#{@model_class.themis_default_validation.inspect}` " \
                "validation is already used as default"
          raise ArgumentError.new(msg)
        end
      end
      private :validate!

    end  # class ValidationSetDefiner
  end  # module ActiveRecordExtension
end  # module Themis
