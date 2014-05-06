require 'spec_helper'

describe Refinery::WordPress::Dump, :type => :model do
  let(:dump) { test_dump }

  it "should create a Dump object given a xml file" do
    expect(dump).to be_a Refinery::WordPress::Dump
  end

  it "should include a Nokogiri::XML object" do
    expect(dump.doc).to be_a Nokogiri::XML::Document
  end

  describe "#tags" do
    let(:tags) do
      [ Refinery::WordPress::Tag.new('css'), Refinery::WordPress::Tag.new('html'),
        Refinery::WordPress::Tag.new('php'), Refinery::WordPress::Tag.new('ruby')]
    end

    it 'finds all tags' do
      expect(dump.tags.count).to eq 4
    end

    it 'returns a tag' do
      expect(dump.tags.first).to be_a(Refinery::WordPress::Tag)
    end

    it "returns all included tags" do
      tags.each do |tag|
        expect(dump.tags).to include(tag)
      end
    end
  end

  describe "#categories" do
    let(:categories) do
      [ Refinery::WordPress::Category.new('Rant'), Refinery::WordPress::Category.new('Tutorials'),
       Refinery::WordPress::Category.new('Uncategorized') ]
    end

    it 'finds all categories' do
      expect(dump.categories.count)
    end

    it 'returns a category' do
      expect(dump.categories.first).to be_a(Refinery::WordPress::Category)
    end

    it "returns all included categories" do
      categories.each do |cat|
        expect(dump.categories).to include(cat)
      end
    end
  end

  describe "#pages" do
    it "returns all included pages" do
      expect(dump.pages.count).to eq 3
    end

    it 'returns pages' do
      expect(dump.pages.first).to be_a(Refinery::WordPress::Page)
    end

    context 'only_published is true' do
      it "returns only published pages" do
        expect(dump.pages(true).count).to eq(2)
      end
    end
  end

  describe "#authors" do
    it "returns all authors" do
      expect(dump.authors.count).to eq 1
    end

    it 'returns an author' do
      expect(dump.authors.first).to be_a(Refinery::WordPress::Author)
    end
  end

  describe "#posts" do
    it "returns all posts" do
      expect(dump.posts.count).to eq 3
    end

    it 'returns a post' do
      expect(dump.posts.first).to be_a(Refinery::WordPress::Post)
    end

    it "returns only published posts with only_published=true" do
      expect(dump.posts(true).count).to eq(2)
    end
  end

  describe "#attachments" do
    it "returns all attachments" do
      expect(dump.attachments.count).to eq(2)
    end

    it 'returns an attachment' do
      expect(dump.attachments.first).to be_a(Refinery::WordPress::Attachment)
    end
  end
end
