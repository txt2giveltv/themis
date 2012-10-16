module Themis
  # All stuff related to ActiveRecord.
  # Mainly it provides {AR::BaseExtension} to extend ActiveRecord::Base.
  module AR
    extend ActiveSupport::Autoload

    autoload :Callbacks
    autoload :AssociationExtension
    autoload :BaseExtension
    autoload :ModelProxy
    autoload :ValidationSet
    autoload :HasValidationMethod
    autoload :UseValidationMethod
    autoload :UseNestedValidationOnMethod
  end  # module AR
end  # module Themis
