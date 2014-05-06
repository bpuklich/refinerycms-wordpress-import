require 'spec_helper'

describe Refinery::WordPress::Attachment, :type => :model do
  context "with an image attachment" do
    let(:attachment) { test_dump.attachments.first }

    it 'reads attachment data from the XML dump' do
      expect(attachment.title).to eq('200px-Tux.svg')
      # doesn't get exported atm. for some reason
      expect(attachment.description).to   eq('')
      expect(attachment.url).to           eq('http://localhost/wordpress/wp-content/uploads/2011/05/200px-Tux.svg_.png')
      expect(attachment.file_name).to     eq('200px-Tux.svg_.png')
      expect(attachment.post_date).to     eq(DateTime.new(2011, 6, 5, 15, 26, 51))
      expect(attachment).to               be_an_image()
    end

    describe "#to_refinery" do
      before do
        @image = attachment.to_refinery
      end

      it "should create an Image from the Attachment" do
        expect(@image).to be_a(Refinery::Image)
      end

      it "should copy the attributes from Attachment" do
        expect(@image.created_at).to eq(attachment.post_date)
        expect(@image.image.url).to end_with(attachment.file_name)
      end
    end

    describe "#replace_url" do
      let(:post) { Refinery::Blog::Post.first }

      before do
        test_dump.authors.each(&:to_refinery)
        test_dump.posts.each do |p|
          # allow duplicates, as there is a duplicate post in the test dump
          p.to_refinery(true)
        end
        @image = attachment.to_refinery

        attachment.replace_url
      end

      it 'has a new url' do
        expect(post.body).to_not include(attachment.url)
        expect(post.body).to_not include('200px-Tux.svg_-150x150.png')
        expect(post.body).to_not include('wp-content')
      end

      it "replaces the old urls with the new one in BlogPosts" do
        expect(post.body).to include(@image.image.url)
      end
    end
  end

  context "a file attachment" do
    let(:attachment) { test_dump.attachments.last }

    it 'reads the data from the XML dump' do
      expect(attachment.title).to eq('cv')
      expect(attachment.url).to eq('http://localhost/wordpress/wp-content/uploads/2011/05/cv.txt')
      expect(attachment.file_name).to eq('cv.txt')
      expect(attachment.post_date).to eq(DateTime.new(2011, 6, 6, 17, 27, 50))
      expect(attachment).to_not be_an_image()
    end

    describe '#to_refinery' do
      before do
        @resource = attachment.to_refinery
      end

      it 'creates a Refinery::Resource' do
        expect(Refinery::Resource).to have(1).record()
        expect(@resource).to be_a(Refinery::Resource)
      end

      it "copies the attributes from the attachment" do
        expect(@resource.created_at).to eq(attachment.post_date)
        expect(@resource.file.url).to end_with(attachment.file_name)
      end

    end

    describe '#replace_resource_url' do
      let(:page_part) { Refinery::Page.last.parts.first }

      before do
        test_dump.pages.each(&:to_refinery)
        @resource = attachment.to_refinery
        attachment.replace_url
      end

      it 'has a new url' do
        expect(page_part.body).to_not include(attachment.url)
        expect(page_part.body).to_not include('wp-content')
      end

      it "replaces the old urls in the generated BlogPosts" do
        expect(page_part.body).to include(@resource.file.url)
      end
    end
  end
end
