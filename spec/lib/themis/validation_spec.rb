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
        it 'should apply defined validations to model' do
          class User < SpecModel(:name => :string)
            include CommonValidation
          end
          User.should have(2).validators
        end

        it "should work with .validate method" do
          stub_const("BasicValidation",
            Module.new do
              self.extend Themis::Validation
              validate :validate_weight

              def validate_weight
                errors.add(:weight, "invalid")
              end
            end
          )

          class Thing < SpecModel(:weight => :integer)
            include BasicValidation
          end

          thing = Thing.new
          thing.should have(1).error_on(:weight)
        end
      end

      context 'in another class' do
        it 'should raise error' do
          expect {
            Class.new { include CommonValidation }
          }.to raise_error(RuntimeError,
            "Validation module `CommonValidation` can be included only in another " \
            "validation module or in ActiveRecord model"
          )
        end
      end
    end

    context 'when other than `validates*` method is used' do
      it 'should delegate to super' do
        expect {
          Module.new do
            self.extend Themis::Validation
            stupid_method
          end
        }.to raise_error(NameError)
      end
    end

  end
end
