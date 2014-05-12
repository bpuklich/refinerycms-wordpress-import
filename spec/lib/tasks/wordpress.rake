require 'spec_helper'

describe 'Wordpress rake tasks' do
  before(:all) do
    let(:dump) { test_dump }
  end
# ------------------------------------- Begin blog processing tasks --------------------------------------------------
  describe 'wordpress:import_categories' do
    include_context 'rake'

    it 'imports all the categories' do
      subject.invoke
      expect(Tag.count).to eq(3)
    end
  end

  describe 'wordpress:import_tags' do
    include_context 'rake'

    it 'imports all the tags' do
      subject.invoke
      expect(Tag.count).to eq(3)
    end
  end


  describe 'wordpress:blog_reset' do
    include_context 'rake'

    it 'resets all blog tables' do
      subject.invoke

      expect(Refinery::Blog.count).to eq(0)
      expect(Tag.count).to eq(0)
    end
  end

  describe 'wordpress:import_blog' do
    include_context 'rake'

    context 'filename not given' do
      subject.invoke
      expect(it).to raise_error('Please specify file_name as a rake parameter (use [filename] after task_name...)')
    end

    context 'filename supplied' do
      subject.invoke(testfile)
      expect(Refinery::Blog::Post.count).to eq(dump.posts.unique.count)
    end

    context 'ONLY_PUBLISHED specified' do
      subject.invoke(testfile)
      expect(Refinery::Blog::Post.count).to eq(dump.posts.published)
    end

    context 'ALLOW_DUPLICATES specified' do
      subject.invoke(testfile)
      expect(Refinery::Blog::Post.count).to eq(dump.posts)
    end
  end

  describe 'wordpress:reset_and_import_blog' do
    # include_context 'rake'
    # 'wordpress:reset_blog'.invoke
    # 'wordpress:import_blog(testfile)'.invoke
  end
# ------------------------------------- End blog processing tasks ----------------------------------------------------

# ------------------------------------- Begin CMS processing tasks ---------------------------------------------------

  describe 'wordpress:cms_reset' do
    include_context 'rake'

    it 'deletes all pages with above the offset_id' do
      before do
  #       ensure there is at least one page above the offset.
        Refinery::Page.create! :id => 1001, :title => 'DeleteMe'
      end
      subject.invoke

      expect(Refinery::Page.where('id>?', 1000).count).to eq(0)
    end
  end

  describe 'wordpress:import_pages' do
    include context 'rake'

    context 'filename not given' do
      subject.invoke
      expect(it).to raise_error('Please specify file_name as a rake parameter (use [filename] after task_name...)')

      context 'filename given' do
        before do
          @page_count = Refinery::Page.count
        end

        subject.invoke(testfile)
        expect(Refinery::Page.count).to eq(@page.count+total_unique_pages)
      end
    end
  end

  describe 'wordpress:reset_and_import_pages' do
     # include_context 'rake'
    # 'wordpress:reset_pages'.invoke
    # 'wordpress:import_pages(testfile)'.invoke

  end
# ------------------------------------- End page processing tasks ----------------------------------------------------

# ------------------------------------- Begin media processing tasks -------------------------------------------------

  describe 'wordpress:media_reset' do
    include_context 'rake'

    it 'resets all media tables' do
      subject.invoke

      expect(Refinery::Image.count).to eq(0)
      expect(Refinery::Resource.count).to eq(0)
    end
  end

  describe 'wordpress:import_media' do
    subject.invoke(testfile)
  end

  describe 'wordpress:reset_and_import_media' do
     # include_context 'rake'
    # 'wordpress:reset_blog'.invoke
    # 'wordpress:import_blog(testfile)'.invoke

  end

  describe 'wordpress:reset_all' do
    # include_context 'rake'
    # 'wordpress:reset_and_import_blog'.invoke
    # 'wordpress:reset_and_import_pages'.invoke
    # 'wordpress:reset_and_import_media'.invoke
  end
end