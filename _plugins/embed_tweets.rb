# frozen_string_literal: true
class TweetEmbedGenerator < Jekyll::Generator
  def generate(site)
    return if !site.config["embed_tweets"]

    all_notes = site.collections['notes'].docs
    all_posts = site.posts
    all_pages = site.pages
    all_docs = all_notes + all_posts + all_pages

    all_docs.each do |current_note|
      current_note.content.gsub!(
        /^https?:\/\/twitter\.com\/(?:#!\/)?(\w+)\/status(es)?\/(\d+)$/i,
        <<~HTML
          <blockquote class="twitter-tweet">
           Esse tuíte não pode ser exibido. <a href="#{'\0'}">Tente vê-lo no Twitter.</a>
          </blockquote>
          <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
        HTML
      )
    end
  end
end
