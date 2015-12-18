require 'spec_helper'

describe "Wordpress rake tasks" do
  let(:filename) { File.expand_path(File.join(File.dirname(__FILE__), '../../fixtures/wordpress_dump.xml')) }
  before do
    ENV['SILENT'] = "1"
  end
  after do
    Rake::Task[task_name].reenable
    Rake::Task[:environment].reenable
    ENV['ONLY_PUBLISHED'] = ENV['ALLOW_DUPLICATES'] = nil
  end

  describe 'wordpress:reset_blog' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'resets all blog tables' do
      subject.invoke
      expect(Refinery::Blog::Post.count).to eq(0)
      expect(Refinery::Blog::Category.count).to eq(0)
      expect(ActsAsTaggableOn::Tag.count).to eq(0)
    end
  end

  describe 'wordpress:reset_pages' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'deletes all pages above the offset_id' do
      Refinery::Page.create! :id => 1001, :title => 'DeleteMe'
      subject.invoke
      expect(Refinery::Page.where('id>?', 1000).count).to eq(0)
    end
  end

  describe 'wordpress:reset_media' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'resets all media tables' do
      subject.invoke
      expect(Refinery::Image.count).to eq(0)
      expect(Refinery::Resource.count).to eq(0)
    end
  end

  describe 'wordpress:import_categories' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'imports all the categories' do
      subject.invoke(filename)
      expect(Refinery::Blog::Category.count).to eq(3)
    end
  end

  describe 'wordpress:import_tags' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'imports all the tags' do
      subject.invoke(filename)
      expect(ActsAsTaggableOn::Tag.count).to eq(4)
    end
  end

  describe 'wordpress:import_blog' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it 'imports blog posts' do
      subject.invoke(filename)
      expect(Refinery::Blog::Post.count).to eq(3)
    end

    it 'imports ONLY_PUBLISHED blog posts' do
      ENV['ONLY_PUBLISHED'] = "1"
      subject.invoke(filename)
      expect(Refinery::Blog::Post.count).to eq(2)
    end

    it 'imports duplicate blog posts with ALLOW_DUPLICATES specified' do
      ENV['ALLOW_DUPLICATES'] = "1"
      subject.invoke(filename)
      expect(Refinery::Blog::Post.count).to eq(4)
    end
  end

  describe 'wordpress:import_pages' do
    before do
      @page_count = Refinery::Page.count
    end

    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it "imports pages" do
      subject.invoke(filename)
      expect(Refinery::Page.count).to eq(@page_count+4)
      # expect(Refinery::Page.count).to eq(@page_count+total_unique_pages)
    end

    it "imports ONLY_PUBLISHED pages" do
      ENV['ONLY_PUBLISHED'] = "1"
      subject.invoke(filename)
      expect(Refinery::Page.count).to eq(@page_count+3)
      # expect(Refinery::Page.count).to eq(@page_count+total_unique_pages)
    end
  end

  describe 'wordpress:import_media' do
    it "depends on Rails environment task" do
      expect(subject).to depend_on(:environment)
    end

    it "imports media" do
      subject.invoke(filename)
      expect(Refinery::Image.count).to eq(1)
    end
  end
end

describe 'wordpress:reset_and_import_blog' do
  # include_context 'rake'
  # 'wordpress:reset_blog'.invoke
  # 'wordpress:import_blog(testfile)'.invoke
end

describe 'wordpress:reset_and_import_pages' do
   # include_context 'rake'
  # 'wordpress:reset_pages'.invoke
  # 'wordpress:import_pages(testfile)'.invoke

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
