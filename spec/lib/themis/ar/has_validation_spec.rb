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

    class Song < SpecModel(:name => :string, :artist => :string, :rating => :integer)
      has_validation :soft do |model|
        model.validates_presence_of :name
      end

      has_validation :hard, NameValidation do |model|
        model.validates_presence_of :artist
      end
    end
  end


  describe ".has_validation" do
    let(:song) { Song.new }

    it "should create validations" do
      Book.themis_validation_sets.keys.should =~ [:soft, :hard]

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
            has_validation :base do |model|
              model.include NameValidation
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

    context 'when non-module and no block are passed' do
      it 'should not raise ArgumentError' do
        expect {
          Class.new(ActiveRecord::Base) do
            has_validation :soft
          end
        }.to_not raise_error
      end
    end

    context 'with :default option' do
      it 'should set default validation when object is initialized' do
        class Human < SpecModel(:name => :string)
          has_validation :soft, NameValidation, :default => true
        end
        human = Human.new

        human.themis_validation.should == :soft
        human.should_not be_valid
        human.should have(1).error_on :name
      end

      it 'should warn when default validation is already specified' do
        expect {
          class Human < SpecModel(:name => :string)
            has_validation :soft, NameValidation, :default => true
            has_validation :hard, NameValidation, :default => true
          end
        }.to warn_message('WARNING: validation `soft` is already used as default on Human')
      end

      it 'should affect nested models' do
        class Human < SpecModel(:name => :string, :location_id => :integer)
          attr_accessible :location
          has_validation :soft, NameValidation, :nested => :location, :default => true
          belongs_to :location
        end

        class Location < SpecModel(:planet => :string)
          has_many :humans
          has_validation :soft do |model|
            model.validates_presence_of :planet
          end
        end

        location = Location.new
        human    = Human.new(:location => location)
        human.themis_validation.should == :soft
        location.themis_validation.should == :soft
      end
    end

    context 'when conditional validation is used' do
      it 'should handle it correctly' do
        stub_const("ConditionalValidation",
          Module.new do
            self.extend Themis::Validation
            validates_presence_of :name, :if => :old?
          end
        )
        class Human < SpecModel(:name => :string, :age => :integer)
          attr_accessible :age
          has_validation :conditional, ConditionalValidation, :default => true

          def old?
            age.to_i > 60
          end
        end

        alter_mann = Human.new(:age => 97)
        junge      = Human.new(:age => 16)

        alter_mann.should be_invalid
        alter_mann.should have(1).error_on :name
        junge.should be_valid

        alter_mann.use_no_validation
        alter_mann.should be_valid
      end
    end

    context 'when validation with given name already defined' do
      it 'should extend existing validation set' do
        class Article < SpecModel(:title => :string, :content => :string)
          has_validation :soft do |model|
            model.validates_presence_of :title
          end

          has_validation :soft do |model|
            model.validates_presence_of :content
          end
        end

        article = Article.new
        article.use_validation(:soft)
        article.should have(1).error_on(:title)
        article.should have(1).error_on(:content)
      end
    end

    context 'with :nested option' do
      before do
        class Article < SpecModel(:name => :string, :author_id => :integer, :reviewer_id => :integer)
          belongs_to :author
          belongs_to :reviewer, :class_name => "Author"

          has_validation :soft, NameValidation, :nested => :reviewer
          has_validation :hard, NameValidation
        end

        class Author < SpecModel(:name => :string)
          attr_accessible :name

          has_many :articles
          has_many :reviewed_articles, :class_name => "Article"

          belongs_to :friend, :class_name => "Author"
          has_many :friends, :class_name => "Author"

          has_validation :soft, NameValidation, :nested => :articles
          has_validation :hard, NameValidation, :nested => [:articles, :friends]
          has_validation :no_association, NameValidation, :nested => :name
        end

        @author   = Author.new(:name => "Rudyard Kipling")
        @reviewer = Author.new
        @friend   = Author.new
        @article  = Article.new

        @author.articles << @article
        @article.author = @author

        @author.friends << @friend

        @article.reviewer = @reviewer
        @reviewer.reviewed_articles << @article

        @author.themis_validation.should be_nil
        @article.themis_validation.should be_nil
        @reviewer.themis_validation.should be_nil
      end

      context 'as a symbol' do
        context 'when association is has_many' do
          it 'should set validation on nested models' do
            @author.use_validation(:soft)
            @article.themis_validation.should == :soft
          end
        end

        context 'when association is belongs_to' do
          it 'should set validation on nested model' do
            @article.use_validation(:soft)
            @reviewer.themis_validation.should == :soft
          end
        end
      end

      context 'as an array' do
        it 'should set validation on all listed association' do
          @author.use_validation(:hard)
          @author.articles.first.themis_validation.should == :hard
          @author.friends.first.themis_validation.should == :hard
        end
      end

      context 'when nested option is not an association' do
        it 'should raise an error' do
          expect { @author.use_validation :no_association }.
            to raise_error(RuntimeError, %q[`name` is not an association on Author])
        end
      end
    end


    describe 'multiple tags syntax' do
      before do
        class Band < SpecModel(:drummer => :string, :bass => :string, :guitar => :string)
          has_validation(:rhythm_section, :punk_rock) do |model|
            model.validates_presence_of :drummer
            model.validates_presence_of :bass
          end

          has_validation(:punk_rock) do |model|
            model.validates_presence_of :guitar
          end
        end
      end

      let(:band) { Band.new }

      describe 'rhythm_section validation' do
        it 'should validate drummer and bass' do
          band.use_validation(:rhythm_section)
          band.should have(1).error_on(:drummer)
          band.should have(1).error_on(:bass)
        end
      end

      describe 'punk_rock validation' do
        it 'should validate drummer, bass and guitar' do
          band.use_validation(:punk_rock)
          band.should have(1).error_on(:drummer)
          band.should have(1).error_on(:bass)
          band.should have(1).error_on(:guitar)
        end
      end

      context 'default option for multiple validations' do
        it 'should raise' do
          expect {
            class Entity < SpecModel()
              has_validation :soft, :hard, :default => true
            end
          }.to raise_error(RuntimeError, "Can not set default to multiple validations")
        end
      end
    end
  end
end
