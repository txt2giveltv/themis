module Themis
  module AR
    # Extends ActiveRecord::Associations::Association
    # Hooks load_target method with to process after_association_loaded callback.
    module AssociationExtension
      extend ActiveSupport::Concern

      # Run original load_target method and process after_association_loaded
      # callback.
      def load_target_with_after_association_loaded(*args, &block)
        result = load_target_without_after_association_loaded(*args, &block)

        if callback = self.owner._after_association_loaded_callbacks[self.reflection.name]
          callback.call(self)
        end

        result
      end

      included do
        alias_method_chain :load_target, :after_association_loaded
      end
    end
  end
end
