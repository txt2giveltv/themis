module Themis
  module AR
    extend ActiveSupport::Autoload

    autoload :BaseExtension
    autoload :ModelProxy
    autoload :ValidationSet
    autoload :HasValidationMethod
    autoload :UseValidationMethod
  end  # module AR
end  # module Themis
