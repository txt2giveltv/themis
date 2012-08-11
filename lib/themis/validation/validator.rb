module Themis
  module Validation
    class Validator
      attr_reader :name, :args

      def initialize(name, args)
        @name, @args = name, args
      end
    end
  end
end
