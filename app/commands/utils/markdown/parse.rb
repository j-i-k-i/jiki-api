class Utils::Markdown::Parse
  include Mandate

  initialize_with :text

  def call
    return "" if text.blank?

    sanitized_html
  end

  private
  memoize
  def sanitized_html
    # Remove HTML comments and sanitize potentially dangerous content
    remove_comments = Loofah::Scrubber.new do |node|
      node.remove if node.name == "comment"
    end

    Loofah.fragment(raw_html).
      scrub!(remove_comments).
      scrub!(:escape).
      to_s
  end

  memoize
  def raw_html
    # Parse markdown and render to HTML using CommonMarker
    Commonmarker.to_html(text, options: {
      parse: { smart: true },
      render: { unsafe: true }
    })
  end
end
