module Themis
  module Validation

    # Simple structure to store information about methods called on
    # {Themis::Validation validation module}. It saves name and arguments
    # of validation method in order to apply it on model latter.
    class Validator
      attr_reader :name, :args

      # @param [Symbol, String] name validation method name, e.g. "validates_presence_of"
      # @param [Array] args arguments of method
      def initialize(name, args)
        @name, @args = name, args
      end
    end

  end  # Validation
end  # Themis
