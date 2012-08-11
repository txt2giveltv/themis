module Themis
  module ActiveRecord
    module BaseExtension

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
          self.themis_validations ||= []
          self.themis_default_validation ||= nil

          options = validation_module_and_options.extract_options!
          validation_module = validation_module_and_options.first

          # initialize
          validation_name = options[:as].try(:to_sym)
          is_default      = options[:default] || false

          # Validate
          unless validation_name
            raise(ArgumentError.new("option `:as` is required"))
          end
          if !validation_module && !block_given?
            raise ArgumentError.new("Validation module or block must be given")
          end
          if themis_validations.include?(validation_name)
            raise ArgumentError.new("validation `#{validation_name.inspect}` already defined")
          end
          if is_default && themis_default_validation
            raise ArgumentError.new("`#{themis_default_validation.inspect}` validation is already marked as default")
          end

          # Add validation name to class list of validations
          themis_validations << validation_name

          # Define validators on ActiveRecord model
          with_options(:if => lambda { @themis_validation == validation_name }) do |model|
            if validation_module
              validation_module.validators.each do |validator|
                model.send(validator.name, *validator.args)
              end
            end
            block.call(model) if block_given?
          end

          # Add after_initialize hook to set default validation
          if is_default
            self.themis_default_validation = validation_name
            after_initialize { @themis_validation = validation_name }
          end
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
      end  #  module InstanceMethods

    end  #  module BaseExtension
  end  #  module ActiveRecord
end  #  module Themis
