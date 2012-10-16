module Themis
  module AR
    # Encapsulates {Themis::AR::BaseExtension#use_nested_validation_on} method
    class UseNestedValidationOnMethod

      # @param [ActiveRecord::Base] model base mdoel
      # @param [Array<Symbol>] associations associations on base model
      # @param [Hash<] nested_associations deep nested associations
      def initialize(model, associations, nested_associations)
        @model = model
        @associations = associations
        @nested_associations = nested_associations
      end

      # Trigger calling use_nested_validation_on on associations and adds
      # after_association_loaded hooks.
      def execute
        # Set themis_default_nested for current model
        @model.themis_default_nested = @associations unless @associations.empty?

        process_nested_validations
        add_after_association_loaded_hooks
      end

      # Iterate over associations and recursively call #use_nested_validation_on
      def process_nested_validations
        @nested_associations.each do |association_name, nested|
          reflection  = @model.reflect_on_association(association_name)
          model_class = reflection.class_name.constantize
          model_class.use_nested_validation_on(nested)
        end
      end

      # Add after_association_loaded hooks to associations so when association
      # is loaded it would have same validation as base model.
      def add_after_association_loaded_hooks
        @associations.each do |association_name|
          @model.after_association_loaded(association_name) do |association|
            validation = association.owner.themis_validation
            target     = association.target

            if validation
              if target.respond_to?(:each)
                target.each { |model| model.use_validation(validation) }
              elsif target.is_a? ActiveRecord::Base
                target.use_validation(validation) if validation
              end
            end
          end
        end
      end

    end
  end
end
