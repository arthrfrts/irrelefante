require "jekyll-json-feed"

module JekyllJsonFeedLinkPatch
  ORIGINAL = '"url": {{ post.url | absolute_url | jsonify }},'

  PATCHED = <<~LIQUID.strip
    "url": {{ post.url | absolute_url | jsonify }},
    {% if post.external_url %}"external_url": {{ post.external_url | jsonify }},{% endif %}
  LIQUID

  def content_for_file(file_path, file_source_path)
    page = super
    page.content = page.content.sub(ORIGINAL, PATCHED)
    page
  end
end

JekyllJsonFeed::Generator.prepend(JekyllJsonFeedLinkPatch)
