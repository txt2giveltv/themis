module Themis
  module AR
    # It wraps a model class to override validation parameters
    # and add(update) :if option.
    # Also it provides some DSL syntax to include validation modules.
    #
    # See where exactly it does its job:
    #   class User
    #     has_validation :soft do |validation|
    #       validation.class  # => ModelProxy
    #     end
    #   end
    class ModelProxy
      # @param [ActiveRecord::Base] model_class
      # @param [Proc] condition lambda which is passed as :if option for conditional validation
      def initialize(model_class, condition)
        @model_class = model_class
        @condition   = condition
      end

      # Defines conditional validations from module.
      # @param [Themis::Validation] validation_module any module extended by {Themis::Validation}
      def include(validation_module)
        validation_module.validators.each do |validator|
          cargs = args_with_condition(validator.args)
          @model_class.send(validator.name, *cargs)
        end
      end

      # Defines conditional validation by adding(updating) :if option
      # to original method call.
      def method_missing(*args)
        cargs = args_with_condition(args)
        @model_class.send(*cargs)
      end


      # Build new arguments with modified :if option to make validation
      # conditional.
      # @param [Array] arguments validation method and its options
      def args_with_condition(arguments)
        # Ala deep duplication to not override original array.
        args = arguments.map { |v| v.is_a?(Symbol) ? v : v.dup }

        if args.last.is_a?(Hash)
          old_opts = args.pop
          args << build_opts(old_opts)
        else
          args << build_opts
        end

        args
      end

      # Build options for validator with :if option to make validation conditional
      # so it would be used depending on `@themis_validation` value.
      # If :if option already was passed then merge lambdas to create new one and
      # use it as :if option.
      # @param [Hash] old_opts old validator options
      def build_opts(old_opts = nil)
        # define local variable so its value can be addressed in lambda
        condition = @condition
        new_opts = old_opts || {}

        if old_opts && old_opts.has_key?(:if)
          old_if = old_opts[:if]
          final_condition = lambda do
            instance_eval(&old_if) &&
            instance_eval(&condition)
          end
        else
          final_condition = condition
        end

        new_opts[:if] = final_condition
        new_opts
      end
      private :build_opts

    end  # class ModelProxy
  end  # module AR
end  # module Themis
