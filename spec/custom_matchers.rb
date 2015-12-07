module CustomMatcher

  RSpec::Matchers.define :include_an_html_tag do |tag|
    tag = Regexp.escape(tag.to_s)

    chain :with_html_attributes do |attributes_hash|
      @with_attributes_hash = attributes_hash
    end
    chain :without_html_attributes do |attributes_hash|
      @without_attributes_hash = attributes_hash
    end
    match do |html|
      if @with_attributes_hash.nil? and @without_attributes_hash.nil?
        result = html.to_s =~ %r[<#{tag}( [^>]+)?>.*?<\/#{tag}>]m
      end
      @with_attributes_hash.all? do |k,v|
        result ||= html.to_s =~ %r[<#{tag}( [^>]+)? #{Regexp.escape k.to_s}\=(['"])#{Regexp.escape v.to_s}\2( [^>]+)?>]m
      end if @with_attributes_hash and @without_attributes_hash.nil?
      @without_attributes_hash.all? do |k|
        result ||= html.to_s !~ %r[<#{tag}( [^>]+)? #{Regexp.escape k.to_s}\=(['"])\w+?\2( [^>]+)?>]m
      end if @without_attributes_hash and @with_attributes_hash.nil?
      result
    end
  end

  # lifted from markevans/dragonfly/spec/support/simple_matchers.rb match_url and modified
  RSpec::Matchers.define :match_url_file_name do |expected|
    match do |actual|
      actual_path = actual.split('?').first
      expected == actual_path.split('/').last
    end
  end
end