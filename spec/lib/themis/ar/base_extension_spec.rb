require 'spec_helper'

describe Themis::AR::BaseExtension do
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
        it 'should warn' do
          expect {
            class Article < SpecModel()
              has_validation :soft, NameValidation
              has_validation :soft, HardValidation
            end
          }.to warn_message("WARNING: validation `soft` is already defined on Article")
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

    end

    describe '.use_nested_validation_on' do
      context 'flatten arguments' do
        before do
          class Post < SpecModel(:author_id => :integer)
            belongs_to :author

            has_validation :soft
            has_validation :hard
          end

          class Comment < SpecModel(:author_id => :integer, :post_id => :integer)
            belongs_to :author
            belongs_to :post

            has_validation :soft
            has_validation :hard
          end

          class Author < SpecModel()
            has_many :posts
            has_many :comments

            use_nested_validation_on :posts, :comments
            has_validation :soft
            has_validation :hard
          end

          @author = Author.new
          @author.posts << Post.new
          @author.comments << Comment.new
        end

        it 'should set default :nested option for all validations' do
          @author.themis_validation.should be_nil
          @author.use_validation(:soft)

          @author.themis_validation.should == :soft
          @author.posts.first.themis_validation.should == :soft
          @author.comments.first.themis_validation.should == :soft
        end

        it 'should warn when default validation is already defined' do
          expect { Author.use_nested_validation_on(:comments) }.
            to warn_message("WARNING: default nested validation is already defined: `[:posts, :comments]` on Author")
        end
      end

      context 'nested arguments' do
        before do
          class Post < SpecModel(:author_id => :integer)
            belongs_to :author
            has_many :comments

            has_validation :soft
            has_validation :hard
          end

          class Comment < SpecModel(:post_id => :integer)
            belongs_to :post

            has_validation :soft
            has_validation :hard
          end

          class Author < SpecModel()
            has_many :posts

            use_nested_validation_on :posts => :comments
            has_validation :soft
            has_validation :hard
          end

          @comment = Comment.new
          @post    = Post.new
          @author  = Author.new
          @post.comments << @comment
          @author.posts << @post
        end

        it 'should effect on deep nested models' do
          @author.themis_validation.should be_nil
          @post.themis_validation.should be_nil
          @comment.themis_validation.should be_nil

          @author.use_validation(:soft)

          @author.themis_validation.should == :soft
          @post.themis_validation.should == :soft
          @comment.themis_validation.should == :soft
        end
      end

      context 'without arguments' do
        it 'should allow to create a validation' do
          class Post < SpecModel()
            has_validation :draft
            has_validation :published
          end
          Post.should have_themis_validation :draft
          Post.should have_themis_validation :published
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
            to raise_error(ArgumentError, "Unknown validation: `:undefined_validation`")
        end
      end
    end


    describe '#use_no_validation' do
      let(:book) { Book.new }

      it 'sets themis_validation to nil' do
        book.use_no_validation
        book.themis_validation.should be_nil
        book.should_not be_valid
        book.should have(1).error
        book.should have(1).error_on :rating
      end
    end

  end
end
