module Refinery
  module WordPress
    class Dump
      attr_reader :doc

      def initialize(file_name)
        raise "No file specified to import!" if file_name.nil?

        file_name = File.expand_path(file_name)

        raise "Given file '#{file_name}' no file or not readable." \
          unless File.file?(file_name) && File.readable?(file_name)

        file = File.open(file_name)
        @doc = Nokogiri::XML(file)
      end

      def authors
        doc.xpath("//wp:author").collect do |author|
          Author.new(author)
        end
      end

      def pages(only_published=false, page_start_id=0)
        pages = doc.xpath("//item[wp:post_type = 'page']").collect do |page|
          Page.new(page)
        end

        pages = pages.select(&:published?) if only_published
        pages
      end

      def posts(only_published=false)
        posts = doc.xpath("//item[wp:post_type = 'post']").collect do |post|
          Post.new(post)
        end
        posts = posts.select(&:published?) if only_published
        posts
      end

      def tags
        doc.xpath("//wp:tag/wp:tag_slug").collect do |tag|
         Tag.new(tag.text.strip)
        end
      end

      def categories
        doc.xpath("//wp:category/wp:cat_name").collect do |category|
          Category.new(category.text.strip)
        end
      end

      def attachments
        doc.xpath("//item[wp:post_type = 'attachment']").collect do |attachment|
          Attachment.new(attachment)
        end
      end
    end
  end
end
