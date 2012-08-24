require 'themis/engine'

# Extends ActiveRecord to provide switchable validations.
module Themis
  extend ActiveSupport::Autoload

  autoload :Validation
  autoload :AR
end
