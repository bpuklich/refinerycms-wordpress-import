module Refinery
  module WordPress
    class Post < Page
      def tags
        # xml dump has "post_tag" for wordpress 3.1 and "tag" for 3.0
        path = if node.xpath("category[@domain='post_tag']").count > 0
          "category[@domain='post_tag']"
        else
          "category[@domain='tag']"
        end

        node.xpath(path).collect do |tag_node|
          Tag.new(tag_node.text)
        end
      end

      def tag_list
        tags.collect(&:name).join(',')
      end

      def categories
        node.xpath("category[@domain='category']").collect do |cat|
          Category.new(cat.text)
        end
      end

      def meta_keywords
        if node.xpath('//wp:postmeta[wp:meta_key="_msp_keywords"]/wp:meta_value').count > 0
          node.xpath('//wp:postmeta[wp:meta_key="_msp_keywords"]/wp:meta_value').first.content
        end
      end

      def meta_description
        if node.xpath('//wp:postmeta[wp:meta_key="_msp_description"]/wp:meta_value').count > 0
          node.xpath('//wp:postmeta[wp:meta_key="_msp_description"]/wp:meta_value').first.content
        end
      end

      def comments
        node.xpath("wp:comment").collect do |comment_node|
          Comment.new(comment_node)
        end
      end

      def to_refinery(allow_duplicates=false)
        user = ::Refinery::User.find_by_email(creator) || ::Refinery::User.first
        raise "Referenced User doesn't exist! Make sure the authors are imported first."  unless user

        begin
          post = ::Refinery::Blog::Post.new :title => title, :body => content_formatted,
            :draft => draft?, :published_at => post_date,
            :user_id => user.id, :tag_list => tag_list, :meta_keywords => meta_keywords, :meta_description => meta_description
          post.created_at = post_date
          post.save!

          ::Refinery::Blog::Post.transaction do
            categories.each do |category|
              post.categories << category.to_refinery
            end

            comments.each do |comment|
              comment = comment.to_refinery
              comment.post = post
              comment.save
            end
          end
        rescue ActiveRecord::RecordInvalid
          # if the title has already been taken (WP allows duplicates here,
          # refinery doesn't) append the post_id to it, making it unique
          post.title = "#{title}-#{post_id}"
          post.save
        end

        post
      end

      def self.create_blog_page_if_necessary
        # refinerycms wants a page at /blog, so let's make sure there is one
        # taken from the original db seeds from refinery-blog
        unless Refinery::Page.where("link_url = ?", '/blog').exists?
          page = Refinery::Page.create(
            :title => "Blog",
            :link_url => "/blog",
            :deletable => false,
            :position => ((Refinery::Page.maximum(:position, :conditions => {:parent_id => nil}) || -1)+1),
            :menu_match => "^/blogs?(\/|\/.+?|)$"
          )

          Refinery::Page.default_parts.each do |default_page_part|
            page.parts.create(:title => default_page_part, :body => nil)
          end
        end
      end

    end
  end
end
