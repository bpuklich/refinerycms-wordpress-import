module Refinery
  module WordPress
    class Category
      attr_accessor :name

      def initialize(text)
        @name = text
      end

      def ==(other)
        name == other.name
      end

      def to_refinery
        Refinery::Blog::Category.find_or_create_by(title: name)
      end
    end
  end
end
