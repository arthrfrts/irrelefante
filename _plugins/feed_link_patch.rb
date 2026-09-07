require "jekyll-feed"

module JekyllFeedLinkPatch
  PATCHED = <<~LIQUID.strip
    {% if post.external_url %}
    <link href="{{ post.external_url }}" rel="related" type="text/html" title="Permalink" />
    {% endif %}
  LIQUID

  def feed_template
    super.sub(ORIGINAL, PATCHED)
  end
end

JekyllFeed::Generator.prepend(JekyllFeedLinkPatch)
