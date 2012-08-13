module Themis
  module ActiveRecordExtension

    class ModelProxy
      def initialize(model, condition)
        @model     = model
        @condition = condition
      end

      def include(validation)
        validation.validators.each do |validator|
          cargs = args_with_condition(validator.args)
          @model.send(validator.name, *cargs)
        end
      end

      def method_missing(*args)
        cargs = args_with_condition(args)
        @model.send(*cargs)
      end


      # TODO: make sure arguments and its option hash is not changed
      def args_with_condition(arguments)
        args = arguments.dup
        opts = arguments.last

        # define local variable so it can be addressed in lambda
        condition = @condition

        if opts.is_a?(Hash)
          if opts.has_key?(:if)
            old_if = opts[:if]
            opts[:if] = lambda do
              instance_eval(&old_if) &&
              instance_eval(&condition)
            end
          else
            opts[:if] = condition
          end
        else
          args << { :if => condition }
        end

        args
      end

    end  # class ModelProxy
  end  # module ActiveRecordExtension
end  # module Themis
