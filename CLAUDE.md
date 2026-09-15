# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Irrelefante is Arthur Freitas's personal Jekyll site/digital garden (irrelefante.com.br), migrating years of writing from older blogs (Um Filme por Dia, Pão com Mortadela, Tumblr) into one place. It's markdown-in, static-HTML-out, no database. It follows IndieWeb conventions: microformats2 (`h-entry`, `h-review`, `h-card`, `p-*`/`u-*`/`e-*` classes throughout the templates), webmentions, and POSSE-style syndication to Bluesky/Mastodon via Bridgy.

Content license: `CC-BY-NC-SA 4.0` for everything under `_posts` directories. Code license: MIT.

## Commands

```sh
bundle install                    # install Ruby gems (Ruby 3.4, see Gemfile)
bundle exec jekyll serve          # local dev server with live rebuild
bundle exec jekyll build          # production build into _site
bundle exec jekyll webmention     # send/receive webmentions + run syndication (jekyll-webmention_io)
bundle exec rake standard_site:publish   # publish new/changed posts to standard.site (AT Protocol)
```

There is no JS/CSS build step, linter, or test suite — this is a content-and-templates repo. jekyll-compose (in the Gemfile) is available for `bundle exec jekyll post`/`jekyll draft`-style scaffolding if used.

`bundle exec jekyll build` is safe for testing config changes (queues/caches only, no network sends); `bundle exec jekyll webmention` performs live sends to Bridgy/Bluesky/Mastodon — don't run it just to "verify" a fix.

## Git

Never run `git commit` — the user commits changes themselves. Other git operations (status, diff, add, log, show, etc.) are fine.

Content is authored either by hand (markdown files) or via **Pages CMS**, configured in `.pages.yml` at the repo root — that file defines the field schemas (image/media uploads, `reaction`, `syndicate_to`, `review` block, etc.) used by the CMS UI, and is the source of truth for what front matter fields a post is expected to have.

## Content architecture

Posts don't live in a single `_posts/`. Each content type is its own top-level folder with its own `_posts/`, and Jekyll merges them all into one `posts` collection:

- `textos/_posts/` — long-form writing
- `notas/_posts/` — short notes
- `links/_posts/` — link posts (bookmarks/reposts of other people's content)
- `reviews/_posts/` — media reviews (movies, games, etc.)

These map to the `feed.categories` list in `_config.yml` and to the permalink's `:slugified_categories` segment — a post's category is driven by which folder it's in / its front matter `categories`, not by subfolders inside a single `_posts`.

Common front-matter fields to know about (see `.pages.yml` for the full schema):
- `external_url` / `canonical_url` — for link/repost-style posts that point at content published elsewhere first; `reaction` (`reply`/`like`/`repost`) describes the relationship. `_plugins/feed_link_patch.rb` and `_plugins/json_feed_source_override.rb` patch `jekyll-feed`/`jekyll-json-feed` to emit `external_url` in RSS/JSON feeds.
- `review:` block (`item`, `format`, `summary`, `rating`, `poster`) — renders the `h-review` widget; see `_layouts/post.html`, `_includes/blog/review.html`, `_includes/review-widget.html`.
- `syndicate_to` — list of silos (`bluesky`, `mastodon`, `flickr`) this post should be POSSE'd to; defaulted in `_config.yml` to `[bluesky, mastodon]` for all posts.
- `syndication` — populated automatically after a successful send (see below); a list of resulting silo URLs.
- `at_uri` — an AT Protocol URI added automatically by `rake standard_site:publish` (jekyll-standard-site gem) once a post is mirrored to standard.site; don't hand-edit.

Layouts: `_layouts/default.html` (shell) → `_layouts/page.html` / `_layouts/post.html`. `_layouts/post.html` handles both plain posts and review posts (branches on `page.review`), renders the syndication callout, embeds `{% webmentions page.url %}`, and emits hidden `brid.gy/publish/*` links for each `syndicate_to` target (required for Bridgy's source verification). `_includes/blog/post.html` and `_includes/blog/review.html` are the condensed card renderings used in list/archive views.

## Webmentions & POSSE syndication (fragile — read before touching)

Syndication is driven by `jekyll-webmention_io`, configured under `webmentions:` in `_config.yml`, and runs as a **separate GitHub Actions workflow**, not as part of every build:

- `.github/workflows/syndication.yml` runs hourly (`workflow_dispatch` also works) and does `jekyll build` then `jekyll webmention`, then commits any changes to `_data/webmentions/` back to `main`. This is the only place outgoing sends and syndication URL capture actually happen.
- `_data/webmentions/` (`bad_uris.yml`, `lookups.yml`, `outgoing.yml`, `received.yml`) is the plugin's persistent state and **must stay committed**. If it's lost or reset, already-published posts get re-queued and Bridgy rejects the duplicate send.
- Bridgy endpoints are configured per-silo under `webmentions.syndication.*.endpoint` (`https://brid.gy/publish/{silo}`); `response_mapping: syndication: $.url` is what writes the resulting silo post URL back into `syndication:` front matter.
- `bad_uris.yml` failures are tracked by host, so a single stuck/bad `brid.gy` entry can silently suppress *all* future syndication sends until the backoff window expires. If syndication seems to have silently stopped, check this file first.
- Fixed (2026-09): `brid.gy` is whitelisted in `webmentions.bad_uri_policy.whitelist`, so a Bridgy failure on one post/silo no longer host-bans all syndication — each post/silo retries independently via its own attempt counter in `outgoing.yml`.
- `bad_uri_policy` settings (`cache_bad_uris_for`, `whitelist`, `blacklist`) must nest *inside* `bad_uri_policy:`, not sit as siblings — the gem reads `bad_uri_policy['cache_bad_uris_for']`, so a misplaced sibling key is silently ignored. The plugin's syndication docs don't cover this; read the installed gem source instead (`gem contents jekyll-webmention_io`).
- `.github/workflows/standard-site.yml` is unrelated to Bridgy: it runs on push to `main` when files change under `*/_posts/**`, runs `rake standard_site:publish`, and commits the resulting `at_uri` front matter back with `[skip ci]`.

## Other things worth knowing

- `docs/` is gitignored (local Claude Code planning artifacts — plans/specs), as is `js/JekyllWebmentionIO.js` (a generated asset) and `Gemfile.lock` — don't assume files here reflect what's tracked in git.
- `wander/` is a standalone hand-built HTML/JS page (not a Jekyll collection) — treat it as its own mini-app within the site.
- `arquivo.html`, `sobre.md`, `404.md`, `search.json`, `_redirects` are one-off top-level pages/config, not collection content.
