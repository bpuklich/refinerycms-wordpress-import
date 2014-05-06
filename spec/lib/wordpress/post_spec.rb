require 'spec_helper'

describe Refinery::WordPress::Post, :type => :model do

  let(:dump) { test_dump }
  let(:post) { dump.posts.last }

  it 'reads a post from the XML dump file' do
    expect( post.title).to eq('Third blog post')
    expect( post.content).to include('Lorem ipsum dolor sit')
    expect( post.content_formatted).to include('Lorem ipsum dolor sit')
    expect( post.creator).to eq('admin')
    expect( post.post_date).to eq(DateTime.new(2011, 5, 21, 12, 24, 45))
    expect( post.post_id).to eq(6)
    expect( post.parent_id).to eq(nil)
    expect( post.status).to eq('publish')
#     Refinery doesn't use meta_keywords
    # expect( post.meta_keywords).to eq('key1, key2, key3')
    expect( post.meta_description).to eq('meta description')

    expect(post).to eq(test_dump.posts.last)
    expect(post).not_to eq(test_dump.posts.first)

    expect(post.categories).to have(1).category
    expect(post.categories.first).to eq(Refinery::WordPress::Category.new('Rant'))

    expect(post.tags).to have(3).tags
    expect(post.tags).to include(Refinery::WordPress::Tag.new('css'))
    expect(post.tags).to include(Refinery::WordPress::Tag.new('html'))
    expect(post.tags).to include(Refinery::WordPress::Tag.new('php'))
    expect(post.tag_list).to eq('css,html,php')
  end

  describe "#comments" do
    it "should return all attached comments" do
      post.comments.should have(2).comments
    end

    context "the last comment" do
      let(:comment) { post.comments.last }

      it "returns the comment's attributes" do
        expect( post.comments.last.author).to eq('admin')
        expect( comment.email).to             eq('admin@example.com')
        expect( comment.url).to               eq('http://www.example.com/')
        expect( comment.date).to              eq(DateTime.new(2011, 5, 21, 12, 26, 30))
        expect( comment.content).to           include('Another one!')
        expect( comment).to                   be_approved()
      end

      describe "#to_refinery" do
        let(:ref_comment) {comment.to_refinery}

        it "should initialize a Refinery::Blog::Comment (not save it)" do
          Refinery::Blog::Comment.should have(0).records
          ref_comment.should be_new_record
        end

        it "should copy the attributes from Refinery::WordPress::Comment" do
          expect(ref_comment.name).to eq(comment.author)
          expect(ref_comment.email).to eq(comment.email)
          expect(ref_comment.body).to eq(comment.content)
          expect(ref_comment.state).to eq('approved')
          expect(ref_comment.created_at).to eq(comment.date)
          expect(ref_comment.created_at).to eq(comment.date)
        end
      end
    end
  end

  describe "#to_refinery" do
    before do
      @user = Refinery::User.create! :username => 'admin', :email => 'admin@example.com',
        :password => 'password', :password_confirmation => 'password'
    end

    context "with a unique title" do
      before do
        @ref_post = post.to_refinery
      end

      it 'saves a refinery post with all attributes' do
        expect(Refinery::Blog::Post.count).to eq(1)

        expect(@ref_post.title).to             eq(post.title)
        expect(@ref_post.body).to              eq(post.content_formatted)
        expect(@ref_post.draft).to             eq(post.draft?)
        expect(@ref_post.published_at).to      eq(post.post_date)
        expect(@ref_post.author.username).to   eq(post.creator)
        # expect(@ref_post.meta_keywords).to     eq(post.meta_keywords)
        expect(@ref_post.meta_description).to  eq(post.meta_description)
      end

      it "assigns a category for each Refinery::WordPress::Category assigned to this post" do
        expect(@ref_post.categories.count).to eq(post.categories.count)
      end

      it "creates a comment for each Refinery::WordPress::Comment attached to this post" do
        expect(@ref_post.comments.count).to eq(post.comments.count)
      end
    end

    context "with a duplicate title" do
      before do
        # create a post with the same title as ours
        Refinery::Blog::Post.create! :title => post.title, :body => 'Lorem', :author => @user
      end

      context '(duplicate titles allowed)' do
        before do
          @ref_post = post.to_refinery(true)
        end

        it 'saves a record' do
          expect(Refinery::Blog::Post.count).to eq(2)
        end

        it "appends the #post_id to the original title" do
          expect(@ref_post.title).to eq("#{post.title}-#{post.post_id}")
        end

        describe 'it saves the post with all attributes and associations' do
          it "assigns a category for each Refinery::WordPress::Category assigned to this post" do
            expect(@ref_post.categories.count).to eq(post.categories.count)
          end

          it "creates a comment for each Refinery::WordPress::Comment attached to this post" do
            expect(@ref_post.comments.count).to eq(post.comments.count)
          end
        end
      end

      context '(duplicate titles not allowed)' do

        it 'raises an error' do
          expect{post.to_refinery(false)}.to raise_error('Duplicate title. Post not imported.')
        end
      end
    end
  end
end
