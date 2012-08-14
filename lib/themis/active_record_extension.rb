module Themis
  module ActiveRecordExtension

    extend ActiveSupport::Autoload

    autoload :ModelProxy
    autoload :ValidationSet
    autoload :HasValidationMethod
    autoload :UseValidationMethod

    def self.included(base)
      base.extend         ClassMethods
      base.send :include, InstanceMethods
      base.class_eval(<<-eoruby, __FILE__, __LINE__+1)
        attr_reader :themis_validation
        class_attribute :themis_validation_sets
        class_attribute :themis_default_validation

        delegate :has_themis_validation?, :to => "self.class"
      eoruby
    end

    module ClassMethods
      # @param [Symbol] name validation name
      # @param [Module] validation_module optional parameter
      # @option [Symbol] :as name of validation
      # @option [Boolean] :default marks validation as default.
      def has_validation(name, *validation_module_and_options, &block)
        options           = validation_module_and_options.extract_options!
        validation_module = validation_module_and_options.first
        HasValidationMethod.new(self, name, validation_module, options, block).execute!
      end

      def has_themis_validation?(name)
        themis_validation_sets.keys.include?(name.to_sym)
      end
    end  # module ClassMethods

    module InstanceMethods
      def use_validation(validation_name)
        UseValidationMethod.new(self, validation_name).execute!
      end

      def use_no_validation
        @themis_validation = nil
      end
    end  # module InstanceMethods

  end  # module ActiveRecordExtension
end  # module Themis
