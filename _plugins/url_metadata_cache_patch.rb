require "jekyll-url-metadata"
require "date"

# jekyll-url-metadata's own cache (Jekyll::Cache, backed by .jekyll-cache/) is
# gitignored and wiped whenever _config.yml changes, so it never survives a
# fresh checkout - every Cloudflare Pages / CI build re-fetches every
# external_url from scratch. This patch redirects lookups through committed
# _data files instead, the same way jekyll-webmention_io persists its state
# under _data/webmentions.
module URLMetadataCachePatch
  def metadata(input)
    return if !is_input_valid(input) || !is_config_valid()

    site = @context.registers[:site]
    store = (site.data["url_metadata"] ||= {})
    return store[input] if store.key?(input)

    failures = (site.data["url_metadata_failures"] ||= {})
    failure = failures[input]
    return nil if failure && !retry_due?(failure, site)

    result = generate_hashmap(input)

    if result
      store[input] = result
      failures.delete(input)
    else
      failures[input] = {
        "last_attempt" => Date.today.to_s,
        "attempts" => failure ? failure["attempts"].to_i + 1 : 1,
      }
    end

    result
  end

  private

  def retry_due?(failure, site)
    retry_after_days = site.config.dig("url_metadata", "retry_after_days") || 1
    (Date.today - Date.parse(failure["last_attempt"])).to_i >= retry_after_days
  rescue ArgumentError, TypeError
    true
  end
end

Jekyll::URLMetadata.prepend(URLMetadataCachePatch)

Jekyll::Hooks.register :site, :post_write do |site|
  data_dir = site.in_source_dir("_data")
  FileUtils.mkdir_p(data_dir)

  if site.data.key?("url_metadata")
    File.write(File.join(data_dir, "url_metadata.yml"), site.data["url_metadata"].to_yaml)
  end

  if site.data.key?("url_metadata_failures")
    File.write(File.join(data_dir, "url_metadata_failures.yml"), site.data["url_metadata_failures"].to_yaml)
  end
end
