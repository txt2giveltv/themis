module Themis
  module ActiveRecordExtension
    class AttachedValidation
      attr_reader :name, :nested
      def initialize(name, options = {})
        @name              = name
        #@is_default        = options[:default] || false
        #@validation_module = options[:validation_module]
        @nested            = options[:nested]
      end
    end

  end
end
