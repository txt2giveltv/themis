module Themis
  module ActiveRecordExtension

    extend ActiveSupport::Autoload

    autoload :ModelProxy
    autoload :ValidationAttacher
    autoload :AttachedValidation

    def self.included(base)
      base.extend         ClassMethods
      base.send :include, InstanceMethods
      base.class_eval(<<-eoruby, __FILE__, __LINE__+1)
        attr_reader :themis_validation
        class_attribute :themis_validations
        class_attribute :themis_default_validation
      eoruby
    end

    module ClassMethods
      # @param [Symbol] name validation name
      # @param [Module] validation_module optional parameter
      # @option [Symbol] :as name of validation
      # @option [Boolean] :default marks validation as default.
      def has_validation(name, *validation_module_and_options, &block)
        ValidationAttacher.new(self, name, validation_module_and_options, block).attach!
      end
    end  # module ClassMethods

    module InstanceMethods
      def use_validation(validation_name)
        name = validation_name.to_sym
        unless self.class.themis_validations.map(&:name).include?(name)
          raise ArgumentError.new("Unknown validation: `#{name.inspect}`")
        end
        @themis_validation = name

        validation = themis_validations.detect { |tv| tv.name == name }
        nested = validation.nested

        case nested
        when Symbol, String
          set_validation_name_on_assciation(nested, name)
        when Array
          nested.each {|assoc| set_validation_name_on_assciation(assoc, name) }
        end
      end

      def use_no_validation
        @themis_validation = nil
      end

      def set_validation_name_on_assciation(association, validation_name)
        target = send(association)
        case target
        when Array, ActiveRecord::Associations::CollectionProxy
          target.each {|obj| obj.send(:use_validation, validation_name) }
        when ActiveRecord::Base
          target.send(:use_validation, validation_name)
        end
      end
      private :set_validation_name_on_assciation

    end  # module InstanceMethods

  end  # module ActiveRecordExtension
end  # module Themis
