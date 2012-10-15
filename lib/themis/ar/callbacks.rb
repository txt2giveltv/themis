module Themis
  module AR
    # Adds after_association_loaded callback to ActiveRecord::Base
    module Callbacks
      # :nodoc:
      def self.included(base)
        base.extend ClassMethods

        base.class_eval(<<-eoruby, __FILE__, __LINE__+1)
          class_attribute :_after_association_loaded_callbacks
          self._after_association_loaded_callbacks = {}
        eoruby
      end

      # :nodoc:
      module ClassMethods
        # Save callback in appropriate callback collection
        #
        # @example
        #   class User < ActiveRecord::Base
        #     has_many :accounts
        #
        #     # List accounts after loading
        #     after_association_loaded(:accounts) do |association|
        #       association.target.each do |account|
        #         puts account.inspect
        #       end
        #     end
        #   end
        #
        # @param [Symbol] association_name association name as a symbol
        # @yield [ActiveRecord::Associations::Association] a block which receives association
        def after_association_loaded(association_name, &block)
          self._after_association_loaded_callbacks[association_name] = block
        end
      end

    end
  end
end
