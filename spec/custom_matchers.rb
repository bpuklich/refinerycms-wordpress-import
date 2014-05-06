module CustomMatcher

  RSpec::Matchers.define :include_an_html_tag do |tag|
    tag = Regexp.escape(tag.to_s)

    match do |html|
      html.to_s =~ %r[<#{tag}( [^>]+)?>.*?<\/#{tag}>]m
    end
    chain :with_html_attributes do |attributes_hash|
      match do |html|
        attributes_hash.all? do |k,v|
          html.to_s =~ %r[<#{tag}( [^>]+)? #{Regexp.escape k.to_s}\=(['"])#{Regexp.escape v.to_s}\2( [^>]+)?>]m
        end
      end
    end
    chain :without_html_attributes do |attributes_hash|
      match do |html|
        attributes_hash.all? do |k|
          html.to_s !=~%r[<#{tag}( [^>]+)? #{Regexp.escape k.to_s}\=(['"])\w+?\2( [^>]+)?>]m
        end
      end
    end
  end
end