module Themis
  # All stuff related to AcitveRecord.
  # Mainly it provides {AR::BaseExtension} to extend AcitveRecord::Base.
  module AR
    extend ActiveSupport::Autoload

    autoload :BaseExtension
    autoload :ModelProxy
    autoload :ValidationSet
    autoload :HasValidationMethod
    autoload :UseValidationMethod
  end  # module AR
end  # module Themis
