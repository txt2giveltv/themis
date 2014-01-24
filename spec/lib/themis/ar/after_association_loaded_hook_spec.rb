require 'spec_helper'

describe Themis::AR::BaseExtension do
  describe "ActiveRecord::Base" do
    describe 'after association loaded hook' do
      after  { SpecModel.cleanup! }

      before do
        class Article < SpecModel(:author_id => :integer)
          has_many :comments
          belongs_to :author

          use_nested_validation_on :comments, :author
          has_validation :soft
        end

        class Comment < SpecModel(:article_id => :integer)
          belongs_to :article
          has_validation :soft
        end

        class Author < SpecModel()
          has_many :articles
          has_validation :soft
        end

        @author = Author.create

        # No mass assignment to keep compatibility with rails 3.
        @article = Article.new
        @article.author = @author
        @article.save!


        2.times do
          Comment.new.tap{ |comment| comment.article = @article }.save!
        end
      end

      context 'after has_many association is loaded' do
        it 'should set same validation as a parent model has' do
          article = Article.find(@article.id)
          article.use_validation(:soft)
          article.comments.each do |comment|
            comment.themis_validation.should == :soft
          end
        end
      end

      context 'after has_one association is loaded' do
        it 'should set same validation as a parent model has' do
          article = Article.find(@article.id)
          article.use_validation(:soft)
          article.author.themis_validation.should == :soft
        end
      end

    end
  end
end
