# Category-as-folder migration

## Goal

Reorganize posts by category on disk so Jekyll's built-in category-from-directory feature derives each post's category from its location, and drop the explicit `category:` front-matter field that currently duplicates that information.

## Background

Every post in `_posts/` has a `category:` front-matter field (`links`, `notas`, `textos`, or `reviews`), added in a prior pass. The site's permalink (`/:slugified_categories/:year/:month/:day/:title/`) and its `jekyll-archives`-generated category pages (`/textos/`, `/links/`, `/notas/`, `/reviews/`) are driven by Jekyll's computed `page.categories` array, which today comes entirely from that front-matter field.

`.pages.yml` (the Pages CMS config) currently defines only one post collection, `links`, scoped to `_posts/links/` — added in a recent commit ("feat(cms): sets links view"). This looks like the first step of rolling out CMS collections per category, and is the direct motivation for this migration.

### Corrected understanding of Jekyll's directory-based categorization

An earlier version of this spec assumed Jekyll derives a post's category from a subfolder *inside* `_posts` (i.e. `_posts/<category>/2019-...md` → category `<category>`). **This is wrong** and was disproven during implementation: Jekyll's own source (`lib/jekyll/document.rb`, `categories_from_path`) states explicitly:

> Add superdirectories of the special_dir to categories.
> In the case of `es/_posts`, `'es'` is added as a category.
> In the case of `_posts/es`, `'es'` is NOT added as a category.

Verified against a real build: with posts moved into `_posts/<category>/`, every post's `categories` array came back empty — no `/reviews/`, `/notas/`, `/textos/`, `/links/` archive directories were generated at all, breaking every category URL and the review-post CSS/routing.

The layout that actually works is the *reverse* nesting: a separate `_posts` directory **inside** each category folder at the repo root — `links/_posts/`, `notas/_posts/`, `textos/_posts/`, `reviews/_posts/`. Jekyll's reader (`lib/jekyll/reader.rb`) recursively scans every directory in the source tree for a `_posts` subdirectory and reads posts from each one it finds, so this is fully supported (it's the same mechanism used for i18n blogs with `en/_posts/`, `es/_posts/`, etc.), and `categories_from_path` correctly assigns the containing folder (`links`, `notas`, `textos`, `reviews`) as the category for posts found this way.

This changes the physical target layout from the original plan (`_posts/<category>/`) to `<category>/_posts/`, which has knock-on effects on `_config.yml`, the CI workflow, and `.pages.yml` (see below) beyond what the original spec covered.

### `post_url` cross-references

31 posts contain 50 `{% post_url <slug> %}` in-content cross-references to other posts. Jekyll's `post_url` tag (`lib/jekyll/tags/post_url.rb`) matches by relative path and requires a category-prefixed argument once posts are out of a flat `_posts/`. Its matching regex is `^_posts/<category>/<slug>\.[^.]+|^<category>/_posts/?<slug>\.[^.]+` — a category-prefixed reference like `{% post_url reviews/<slug> %}` matches **both** the `_posts/<category>/` and `<category>/_posts/` conventions, so this fix (prefixing every reference with its target's category) is layout-independent and doesn't need to change based on which physical structure is chosen.

## Scope

All four active categories, in one migration:

- `category: links` (143 posts, after a pre-existing typo fix: one post had `category: link` instead of `links`) → `links/_posts/`
- `category: notas` (132 posts) → `notas/_posts/`
- `category: textos` (40 posts) → `textos/_posts/`
- `category: reviews` (35 posts) → `reviews/_posts/`

`fotos` is declared in `_config.yml`'s `feed.categories` list but no post currently uses it — no `fotos/_posts/` folder is created; nothing to move there yet.

Only the existing `links` collection in `.pages.yml` has its `path` updated to match the new location (`_posts/links` → `links/_posts`) — this is maintenance to keep it from silently breaking, not scope expansion. Adding new collections for `textos`/`notas`/`reviews` remains **out of scope**, per an earlier explicit decision.

## Changes

### 1. Pre-cleanup

Fix a front-matter typo found during discovery, before moving anything:

- `_posts/2025-10-27-rattlesnake-kate.md`: `category: link` → `category: links` (singular typo — left as-is it would produce a stray `link/_posts/` folder distinct from `links/_posts/`).

### 2. File moves

Move each post file (via `git mv`, to preserve file history) into `<category>/_posts/`, based on its current `category:` value. No renaming of the filename itself. The old `_posts/` directory at the repo root ends up empty and disappears (git doesn't track empty directories).

### 3. Strip the front-matter field

Remove the `category:` line from all 350 posts' front matter. It becomes redundant: Jekyll will derive the same value from the folder name.

### 4. `_config.yml`

Two changes:

- Remove `category: textos` from the `defaults:` block (scope `path: "_posts"`, `type: "posts"`). Leaving it in place would inject `textos` into *every* post's `categories` array regardless of its actual folder, since Jekyll unions front-matter-derived and directory-derived categories.
- Also remove the `path: "_posts"` key from that same scope entirely (leaving only `type: "posts"`). Jekyll's default-scope path matching is a simple prefix check against each document's relative path (`lib/jekyll/frontmatter_defaults.rb`, `applies_path?` → `path.start_with?(parent_path)`); once posts live at `links/_posts/...`, `notas/_posts/...` etc., none of their relative paths start with the literal string `_posts` anymore, so the existing `path: "_posts"` scope would silently stop matching *any* post — breaking the `syndicate_to: [bluesky, mastodon]` default for every single post. Dropping the `path` key entirely makes the scope apply based on `type: "posts"` alone, which is location-independent and correctly matches every post regardless of which category folder it's in.

**Accepted trade-off:** after this change, a post created outside any of the four `<category>/_posts/` directories will have no category at all — there is no more fallback default. This is expected to be fine given `.pages.yml`'s per-category collection(s) are the intended path for creating new posts going forward.

### 5. Template updates

Convert every read of singular `page.category`/`post.category` (a plain string, previously sourced from front matter) to Jekyll's plural `page.categories`/`post.categories` (an array, now sourced from the folder name). Since each post lives in exactly one category folder, `categories` will always be a single-element array — use `| first` for the CSS-class cases, and `contains "reviews"` (array membership) in place of the old `contains "review"` (substring match) for the review-routing checks.

Five usage sites across five files:

- **`_layouts/post.html`**: CSS class `{{ page.category | slugify: 'latin' }}` → `{{ page.categories | first | slugify: 'latin' }}`; routing check `{% if page.category contains 'review' %}` → `{% if page.categories contains 'reviews' %}`
- **`_includes/blog/post.html`**: CSS class `{{ post.category | slugify: 'latin' }}` → `{{ post.categories | first | slugify: 'latin' }}`
- **`_includes/blog/review.html`**: CSS class `{{ review_post.category | slugify: 'latin' }}` → `{{ review_post.categories | first | slugify: 'latin' }}`
- **`index.html`**: `{% if post.category contains "review" %}` → `{% if post.categories contains "reviews" %}`
- **`_layouts/archive.html`**: `{% if post.category contains "review" %}` → `{% if post.categories contains "reviews" %}`

No other files reference `page.category`/`post.category` (a broad search also matched `_includes/review-widget.html` and the `p-category` CSS class used elsewhere, but those are IndieWeb microformat class names unrelated to Jekyll's category feature, and need no change).

### 6. `post_url` cross-references

Add a category prefix to all 50 `{% post_url <slug> %}` references across 31 posts, matching whichever folder the *target* post lives in (e.g. `{% post_url 2017-07-25-... %}` → `{% post_url reviews/2017-07-25-... %}`). See "Corrected understanding" above — this fix is layout-independent and doesn't change based on the `_posts/<category>` vs `<category>/_posts` decision.

### 7. CI workflow and CMS config

- `.github/workflows/standard-site.yml`: the trigger `paths: ["_posts/**"]` and the commit step's `git status --porcelain _posts` / `git add _posts` all assumed one flat `_posts/` directory. These need to reference all four new locations explicitly (`links/_posts`, `notas/_posts`, `textos/_posts`, `reviews/_posts`).
- `.pages.yml`: the existing `links` collection's `path: _posts/links` → `path: links/_posts`, to keep it pointing at where files actually live now.

### 8. Verification

Run `bundle exec jekyll build` locally (Jekyll 4.4.1, available in this environment) and confirm:

- `site.posts.size` is still 350 (no posts lost or duplicated).
- A sample post from each of the four categories renders at its **unchanged** URL (e.g. a `textos` post still builds to `/textos/2019/08/14/.../`) — folder-derived categories reproduce the same values the front-matter field previously provided.
- Review posts still get the `h-review` class and review-widget layout.
- The `/textos/`, `/links/`, `/notas/`, `/reviews/` archive index pages (via `jekyll-archives`) still list the correct posts, and now actually exist (this is the check that catches the original, disproven assumption if it recurs).
- The post-list CSS class (`post <category>`) still renders correctly on the homepage, archive pages, and individual post pages.
- All 50 `post_url` references resolve (the build fails outright if even one doesn't).

## Out of scope

- Adding new `.pages.yml` collections for `textos`/`notas`/`reviews` (only the existing `links` collection's path is corrected, per an earlier explicit decision).
- Creating a `fotos/_posts/` folder (no posts use that category yet).
- Any changes to the pre-existing schema mismatch between the `links` CMS collection's field list and the front-matter fields already present on migrated/imported link posts (e.g. `syndication`, `redirect_from`, `at_uri`, `canonical_url`, `image`) — noted during discovery but unrelated to this migration.
