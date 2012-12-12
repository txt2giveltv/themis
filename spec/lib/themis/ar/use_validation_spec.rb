require 'spec_helper'

describe "ActiveRecord::Base" do
  after  { SpecModel.cleanup! }

  before do
    stub_const("NameValidation",
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
      has_validation :soft, NameValidation
      has_validation :hard, HardValidation

      # common validation
      validates_numericality_of :rating
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

    context 'with :soft' do
      it 'should use validators from SoftValidation' do
        book.use_validation(:soft)
        book.themis_validation.should == :soft

        book.should_not be_valid
        book.should have(2).error
        book.should have(1).error_on :name
        book.should have(1).error_on :rating
      end
    end

    context 'with :hard' do
      it 'should use validators from HardValidation' do
        book.use_validation(:hard)
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
          to raise_error(ArgumentError, "Unknown validation: `:undefined_validation` for Book")
      end
    end
  end
end
