# Themis

Flexible and modular validations for ActiveRecord models

## Syntax

### Define validation module

    module CommonValidation
      extend Themis::Validation

      validates_presence_of :name
    end


    module CustomerValidation
      extend Themis::Validation

      include CommonValidation

      validates :email, :email => true
      validates_presence_of :birthday
    end

### ActiveRecord model

    class Customer < ActiveRecord::Base
      # Independently which validation is used it always has an effect.
      validates_presence_of :status

      # Validation with module
      has_validation :hard, HardCustomerValidation, :nested => :customer_account

      # Use inline validation
      has_validation :soft, :default => true do |validation|
        validation.include CommonValidation
        validation.validates :logged_at, :presence => true
      end
    end

### Behaviour

    customer = Customer.new
    customer.validation  # => :soft

    # validates_presence_of :status
    # validates_presence_of :name
    # validates :logged_at, :presence => true
    customer.valid?


    # validates_presence_of :status
    # validates :email, :email => true
    # validates_presence_of :birthday
    # run :hard validation on :customer_account
    customer.use_validation(:hard)
    customer.valid?

Pay attention there are  class method and instance method: `.use_validation`, `#use_validation`. They are different.
