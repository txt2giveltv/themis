module Themis
  # :nodoc
  class Engine < Rails::Engine

    initializer 'themis' do
      ActiveSupport.on_load(:active_record) do

        ::ActiveRecord::Base.class_eval do
          include Themis::ActiveRecord::BaseExtension
        end

      end  # on_load
    end  # initializer

  end  # Engine
end  # Themis
