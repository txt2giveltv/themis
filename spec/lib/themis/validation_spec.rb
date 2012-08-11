require 'spec_helper'

describe Themis::Validation do
  before do
    stub_const("CommonValidation",
      Module.new do
        self.extend Themis::Validation
        validates_presence_of :name
        validates :email, :uniqueness => true
      end
    )
  end

  describe 'extended module' do
    describe '#validators' do
      let(:presence_validator) { CommonValidation.validators.first  }
      let(:email_validator)    { CommonValidation.validators.second }

      it 'should be defined by methods in module' do
        presence_validator.name.should == :validates_presence_of
        presence_validator.args.should == [:name]

        email_validator.name.should == :validates
        email_validator.args.should == [:email, {:uniqueness => true}]
      end
    end

    context 'when one module is included' do
      context 'in another validation module' do
        let(:user_validation) do
          Module.new do
            extend Themis::Validation
            include CommonValidation
            validates_uniquness_of :nickname
          end
        end

        it 'should copy validators' do
          user_validation.should have(3).validators
          nickname_validator = user_validation.validators.third
          nickname_validator.name.should == :validates_uniquness_of
          nickname_validator.args.should == [:nickname]
        end
      end

      context 'in ActiveRecord model' do
        let(:user_class) do
          Class.new(::ActiveRecord::Base) do
            include CommonValidation
          end
        end

        it 'should apply defined validations to model' do
          user_class.should have(2).validators
        end
      end

      context 'in another class' do
        it 'should raise error' do
          expect do
            Class.new { include CommonValidation }
          end.to raise_error(RuntimeError,
            "Validation module `CommonValidation` can be included only in another " \
            "validation module or in ActiveRecord model"
          )
        end
      end
    end

  end
end
