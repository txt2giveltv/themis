require 'spec_helper'

describe Themis::ActiveRecordExtension do
  describe "ActiveRecord::Base" do

    after  { SpecModel.cleanup! }

    before do
      stub_const("SoftValidation",
        Module.new do
          self.extend Themis::Validation
          validates_presence_of :name
        end
      )

      stub_const("HardValidation",
        Module.new do
          self.extend Themis::Validation
          validates :name, :format => /\A\w+\Z/
          validates_presence_of :author
        end
      )

      class Book < SpecModel(:name => :string, :author => :string, :rating => :integer)
        use_validation SoftValidation, :as => :soft
        use_validation HardValidation, :as => :hard

        # common validation
        validates_numericality_of :rating
      end

      class Song < SpecModel(:name => :string, :artist => :string, :rating => :integer)
        use_validation :as => :soft do |model|
          model.validates_presence_of :name
        end

        use_validation SoftValidation, :as => :hard do |model|
          model.validates_presence_of :artist
        end
      end
    end


    describe ".use_validation" do
      let(:song) { Song.new }

      it "should create validations" do
        Book.themis_validations.should =~ [:soft, :hard]

        # 1 common validation
        # 1 for soft validation
        # 2 for hard validation
        Book.should have(4).validators
      end


      describe 'when module and block are passed' do
        it 'should use validators from module and from block as well' do
          song.use_validation(:hard)
          song.should_not be_valid
          song.should have(2).errors
          song.should have(1).error_on :name
          song.should have(1).error_on :artist
        end
      end

      describe 'when block is given' do
        it 'should use validators from block' do
          song.use_validation(:soft)
          song.should_not be_valid
          song.should have(1).error
          song.should have(1).error_on :name
        end

        context 'and validation module is included in block scope' do
          it 'should apply validators of module' do
            class Human < SpecModel(:name => :string, :age => :integer)
              use_validation :as => :base do |model|
                model.include SoftValidation
                model.validates_numericality_of :age
              end
            end
            human = Human.new

            human.use_validation(:base)
            human.should be_invalid
            human.should have(1).error_on :name
            human.should have(1).error_on :age
          end
        end
      end

      describe 'when not module and no block are passed' do
        it 'should raise ArgumentError' do
          expect {
            Class.new(ActiveRecord::Base) do
              use_validation :as => :soft
            end
          }.to raise_error(ArgumentError, "Validation module or block must be given to `.use_validation` method")
        end
      end

      describe 'option :as is not given' do
        it 'should raise ArgumentError' do
          expect {
            Class.new(ActiveRecord::Base) do
              use_validation SoftValidation
            end
          }.to raise_error(ArgumentError, "option `:as` is required for `.use_validation` method")
        end
      end

      describe 'with :default option' do
        it 'should set default validation when object is initialized' do
          class Human < SpecModel(:name => :string)
            use_validation SoftValidation, :as => :soft, :default => true
          end
          human = Human.new

          human.themis_validation.should == :soft
          human.should_not be_valid
          human.should have(1).error_on :name
        end

        it 'should raise ArgumentError when default validation is already specified' do
          expect {
            class Human < SpecModel(:name => :string)
              use_validation SoftValidation, :as => :soft, :default => true
              use_validation SoftValidation, :as => :hard, :default => true
            end
          }.to raise_error(ArgumentError, "`:soft` validation is already used as default")
        end
      end

      describe 'when conditional validation is used' do
        it 'should handle it correctly' do
          stub_const("ConditionalValidation",
            Module.new do
              self.extend Themis::Validation
              validates_presence_of :name, :if => :old?
            end
          )
          class Human < SpecModel(:name => :string, :age => :integer)
            attr_accessible :age
            use_validation ConditionalValidation, :as => :conditional, :default => true

            def old?
              age.to_i > 60
            end
          end

          alter_mann = Human.new(:age => 97)
          junge      = Human.new(:age => 16)

          alter_mann.should be_invalid
          alter_mann.should have(1).error_on :name
          junge.should be_valid

          alter_mann.use_validation(nil)
          alter_mann.should be_valid
        end
      end

      describe 'when validation with given name already defined' do
        it 'should raise ArgumentError' do
          expect {
            Class.new(ActiveRecord::Base) do
              use_validation SoftValidation, :as => :soft
              use_validation HardValidation, :as => 'soft'
            end
          }.to raise_error(ArgumentError, "validation `:soft` already defined")
        end
      end

    end

    describe "#use_validation" do
      let(:book) { Book.new }

      context 'validation is not specified' do
        it 'should not use themis validations' do
          book.themis_validation.should be_nil

          book.should_not be_valid
          book.should have(1).error
          book.should have(1).error_on :rating
        end
      end

      context 'with nil' do
        it 'should not use any of themis validations' do
          book.use_validation nil
          book.should_not be_valid
          book.should have(1).error
          book.should have(1).error_on :rating
        end
      end

      context 'with :soft' do
        it 'should use validators from SoftValidation' do
          book.use_validation :soft
          book.themis_validation.should == :soft

          book.should_not be_valid
          book.should have(2).error
          book.should have(1).error_on :name
          book.should have(1).error_on :rating
        end
      end

      context 'with :hard' do
        it 'should use validators from HardValidation' do
          book.use_validation :hard
          book.themis_validation.should == :hard

          book.should_not be_valid
          book.should have(3).errors
          book.should have(1).error_on :name
          book.should have(1).error_on :author
          book.should have(1).error_on :rating
        end
      end

      context 'with undefined validation' do
        it 'should raise ArgumentError' do
          expect { book.use_validation(:undefined_validation) }.
            to raise_error(ArgumentError, "Unknown validation: `:undefined_validation`")
        end
      end
    end

  end
end
