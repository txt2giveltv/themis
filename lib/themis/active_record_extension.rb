module Themis
  module ActiveRecordExtension

    extend ActiveSupport::Autoload

    autoload :ModelProxy
    autoload :ValidationAttacher

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
      # == Usage
      #   class User < ActiveRecord::Base
      #     use_validation BaseValidation, :as => :base
      #
      #     use_validation :as => :soft do |model|
      #       model.validates_presence :name
      #     end
      #
      #     use_validation BaseExtension :as => :hard, :default => true do |model|
      #       model.validates_presence :phone_number
      #     end
      #   end
      #
      # @param [Module] validation_module optional parameter
      # @option [Symbol] :as name of validation
      # @option [Boolean] :default marks validation as default.
      def use_validation(*validation_module_and_options, &block)
        ValidationAttacher.new(self, validation_module_and_options, block).attach!
      end
    end  # module ClassMethods

    module InstanceMethods
      def use_validation(name)
        if name.nil?
          @themis_validation = nil
        else
          unless self.class.themis_validations.include?(name.to_sym)
            raise ArgumentError.new("Unknown validation: `#{name.inspect}`")
          end
          @themis_validation = name.to_sym
        end
      end
    end  # module InstanceMethods

  end  # module ActiveRecordExtension
end  # module Themis
