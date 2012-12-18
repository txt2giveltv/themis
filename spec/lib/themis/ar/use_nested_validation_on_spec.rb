require 'spec_helper'

describe "ActiveRecord::Base" do
  after  { SpecModel.cleanup! }

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
end
