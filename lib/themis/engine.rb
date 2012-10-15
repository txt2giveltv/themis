module Themis
  # :nodoc
  class Engine < Rails::Engine

    initializer 'themis' do
      ActiveSupport.on_load(:active_record) do

        ::ActiveRecord::Associations::CollectionAssociation.class_eval do
          include Themis::AR::AssociationExtension
        end

        ::ActiveRecord::Associations::Association.class_eval do
          include Themis::AR::AssociationExtension
        end

        ::ActiveRecord::Base.class_eval do
          include Themis::AR::BaseExtension
        end

      end  # on_load
    end  # initializer

  end  # Engine
end  # Themis
