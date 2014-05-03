require 'spec_helper'

describe Refinery::WordPress::Page, :type => :model do
  let(:dump) { test_dump }

  let(:page) { test_dump.pages.last }

  it 'creates a page from the XML dump file' do
    expect( page.title).to      eq('About me')
    expect( page.content).to    include('Lorem ipsum dolor sit')
    expect( page.creator).to    eq('admin')
    expect( page.post_date).to eq(DateTime.new(2011, 5, 21, 12, 25, 42))
    expect( page.post_id).to    eq(10)
    expect( page.parent_id).to eq(8)

    expect( page).to eq(dump.pages.last)
    expect( page).not_to eq(dump.pages.first)
  end

  describe "#to_refinery" do
    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::TextHelper

    before do
      # "About me" has a parent page with id 8 in the XML  dump,
      # would otherwise fails creation
      Refinery::Page.create! :id => 8, :title => 'About'

      @count = Refinery::Page.count
      @page = page.to_refinery
    end

    it "creates a new Page object" do
      expect(Refinery::Page.count).to eq(@count + 1)
    end

    it "copies the attributes from Refinery::WordPress::Page" do
      expect(@page.title).to            eq(page.title)
      expect(@page.draft).to            eq(page.draft?)
      expect(@page.created_at).to       eq(page.post_date)
      expect(@page.parts.first.body).to eq("#{simple_format(page.content)}")
    end
  end

  describe "#format_paragraphs" do
    let(:sample_text) do
      text = <<-EOT
        This is sample text.

        Even more text.
        But this time no paragraph.
      EOT
    end

    before do
      @result = page.send(:format_paragraphs, sample_text)
    end

    it "adds paragraphs to the sample text" do
       expect(@result).to include_an_html_tag(:p)
    end
  end
  describe "#format_shortcodes" do

    describe '#rewrite ruby shortcode' do
      let(:sample_text) do
        text = <<-EOT
         [ruby]p "Hello World"[/ruby]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end

      it 'returns <pre/> markup' do
        expect(@result).to include_an_html_tag(:pre).with_html_attributes(:class=>'brush: ruby')
      end
    end #rewrite ruby shortcode

    describe '#rewrite caption shortcode' do
      let(:sample_text) do
        text = <<-EOT
          [caption id="attachment_304" align="alignright" width="300"]
            <img class="size-medium wp-image-304"  title="Test Image Title"
                 src="200px_Tux.svg_.png" alt="Test Image Alt text" width="300" height="198" />Test Image Caption text[/caption]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end

      it '#returns <figure/> markup' do
        expect(@result).to include_an_html_tag(:figure) do fig
          expect(fig).to include_an_html_tag(:img)
          expect(fig).to include_an_html_tag(:figcaption)
        end #fig
      end

      it "strips out image width and height attributes" do
        expect(@result).to include_an_html_tag(:img).without_html_attributes([:width, :height, :style])
      end
    end #rewrite caption shortcode

    describe '#rewrite youtube shortcode' do
      let(:sample_text) do
        text = <<-EOT
          [youtube abcde 100 200]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end

      it 'returns iframe markup' do
        expect(@result).to include_an_html_tag(:p) do para
          expect(para).to include_an_html_tag(:iframe)
            .with_html_attributes(
              :width => '100',
              :height=> '200',
              :src=>'http://www.youtube.com/embed/abcde?version=3&rel=1&fs=1&showsearch=0&showinfo=1&iv_load_policy=1&wmode=transparent')
        end #para
      end #it returns iframe markup
    end #rewrite youtube shortcode
  end #format_shortcodes

  describe "#format_base64_images" do
    let(:sample_text) do
    # the image is a 10x10px red square
      text = <<-EOT
        <img alt="" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVJREFUeNpi/M+ADzAxjEpjAQABBgBBLAETbs/ntQAAAABJRU5ErkJggg==" />
      EOT
    end

    before do
      @result = page.send(:format_base64_images, sample_text, 1000)
    end

    it 'returns a reference to an img src file named for the post-id' do
      expect(@result).to include("src='post1000.png'")
    end

    it 'creates a file containing the decoded image' do
      expect(File.exist?("#{Rails.public_path}/post1000.png")).to be_true
    end

    after do
      File.delete("#{Rails.public_path}/post1000.png")
    end
  end #format_base64_images

end

