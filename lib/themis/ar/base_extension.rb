module Themis
  module AR
    # Extends ActiveRecord::Base to make it support has_validation and use_validation
    # methods.
    # It adds some class attributes to model:
    # * themis_validation - name of validation, symbol or nil
    # * themis_validation_sets - hash where key is symbol(validation name) and value is {ValidationSet}.
    # * themis_default_validation - name of default validation.
    # * themis_default_nested - default value for :nested option
    module BaseExtension
      extend ActiveSupport::Autoload

      # :nodoc:
      def self.included(base)
        base.extend         ClassMethods
        base.send :include, InstanceMethods
        base.send :include, Callbacks

        base.class_eval(<<-eoruby, __FILE__, __LINE__+1)
          attr_reader :themis_validation

          class_attribute :themis_validation_sets
          class_attribute :themis_default_validation
          class_attribute :themis_default_nested

          delegate :has_themis_validation?, :to => "self.class"
        eoruby
      end

      # :nodoc:
      module ClassMethods
        # @overload has_validation(name, options, &block)
        #   Declare validation set using block
        #   @example
        #     has_validation :soft, :nested => :account, :default => true do |validation|
        #       validation.validates_presence_of :some_date
        #     end
        #   @param [Symbol] name name of validation set
        #   @param [Hash] options options: :default, :nested
        #   @param [Proc] block proc which receives {ModelProxy} and defines validators
        #   @option options [Boolean] :default make it validation be used by default
        #   @option options [Symbol, Array<Symbol>] :nested association which should be affected when validation {#use_validation} is called
        #
        # @overload has_validation(name_1, name_2, options, &block)
        #   Declare validation in 2 sets using a block:
        #   @example
        #     has_validation :soft, :hard :nested => :account, :default => true do |validation|
        #       validation.validates_presence_of :some_date
        #     end
        #
        # @overload has_validation(name, validation_module, options, &block)
        #   Declare validation set on model using {Themis::Validation validation module} or(and) block.
        #   @example
        #     has_validation :soft, SoftValidation, :default => true
        #   @param [Symbol] name name of validation set
        #   @param [Module] validation_module module extended by {Themis::Validation}.
        #   @param [Hash] options options: :default, :nested
        #   @param [Proc] block proc which receives {ModelProxy} and defines validators
        #   @option options [Boolean] :default make it validation be used by default
        #   @option options [Symbol, Array<Symbol>] :nested association which should be affect when validation {#use_validation} is called
        def has_validation(*args_and_options, &block)
          options           = args_and_options.extract_options!
          names, args       = args_and_options.partition { |obj| obj.class.in?([String, Symbol]) }
          validation_module = args.first
          Themis::AR::HasValidationMethod.new(self, names, validation_module, options, block).execute!
        end

        # Verify that model has {ValidationSet validation set} with passed name.
        # @param [Symbol] name name of validation set
        def has_themis_validation?(name)
          return false unless themis_validation_sets.present?
          themis_validation_sets.keys.include?(name.to_sym)
        end

        # Set the default value of the +:nested+ option for validations.
        # @example
        #   use_nested_validation_on :author
        #
        # @example
        #   use_nested_validation_on :author, :comments
        #
        # @example
        #   use_nested_validation_on :author => {:posts => :comments }
        #
        # @param [Array<Symbol>, Hash] args an association or associations which should be effected
        def use_nested_validation_on(*args)
          if themis_default_nested
            warn "WARNING: default nested validation is already defined: " \
                 "`#{themis_default_nested.inspect}` on #{self}"
          end

          args         = args.flatten
          deep_nested  = args.extract_options!
          associations = args + deep_nested.keys

          UseNestedValidationOnMethod.new(self, associations, deep_nested).execute
        end
      end  # module ClassMethods

      # :nodoc:
      module InstanceMethods
        # Switch validation.
        # @param [Symbol] validation_name name of {ValidationSet validation set}
        def use_validation(validation_name)
          Themis::AR::UseValidationMethod.new(self, validation_name).execute!
        end

        # Do not use any of {ValidationSet validation sets}.
        def use_no_validation
          @themis_validation = nil
        end
      end  # module InstanceMethods

    end  # module BaseExtension
  end  # module AR
end  # module Themis
