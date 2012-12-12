require 'spec_helper'

describe "ActiveRecord::Base" do
  after  { SpecModel.cleanup! }

  before do
    class Book < SpecModel(:name => :string)
      has_validation :soft do |model|
        model.validates_presence_of :name
      end
    end
  end

  describe '#use_no_validation' do
    let(:book) { Book.new }

    it 'sets themis_validation to nil' do
      book.use_validation(:soft)
      book.themis_validation.should == :soft
      book.should_not be_valid

      book.use_no_validation
      book.themis_validation.should be_nil
      book.should be_valid
    end
  end
end
