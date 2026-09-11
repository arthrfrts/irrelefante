# Category-as-folder Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **SAFETY NOTE FOR THIS EXECUTION PASS:** commits are held off across every task below (see each task's final step) — do NOT run `git commit` anywhere in this pass unless explicitly told otherwise. If a build/verification step (Task 2 or Task 8) is long-running, do not detach into an unsupervised background process and "wait for a notification" — either block on it directly, or report NEEDS_CONTEXT/BLOCKED back to the controller rather than continuing unsupervised. A prior attempt at this same plan had an implementer stall this way and it went on to make unauthorized commits; every task below must return control cleanly, with nothing committed, every time.

**Goal:** Reorganize posts by category on disk (`links/_posts/`, `notas/_posts/`, `textos/_posts/`, `reviews/_posts/` — a separate `_posts` directory *inside* each category folder at the repo root) so Jekyll's real directory-based categorization derives each post's category from its location, and drop the explicit `category:` front-matter field that currently duplicates that information.

**Architecture:** Fix one pre-existing data typo, capture a full pre-migration build as a regression baseline, move files via `git mv` into `<category>/_posts/` (preserving history), strip the now-redundant front-matter field together with the `_config.yml` defaults that would otherwise misbehave, update the 5 Liquid template sites that read the old singular field, add category prefixes to 50 in-content `post_url` cross-references, update the CI workflow and CMS config to match the new file locations, then rebuild and diff against the baseline to prove nothing external changed.

**Tech Stack:** Jekyll 4.4.1 (Ruby/Bundler, already installed in this environment — `bundle exec jekyll -v` succeeds), Liquid templates, Git, Bash (Git Bash on Windows).

**Reference:** `docs/superpowers/specs/2026-09-11-category-as-folder-design.md`

**Important correction from an earlier version of this plan:** Jekyll does **not** derive categories from subfolders *inside* `_posts` (i.e. `_posts/<category>/` does NOT work — verified against Jekyll's own source and a real build, which produced posts with empty `categories` arrays). The layout that actually works is the reverse: `<category>/_posts/` (a `_posts` directory inside each category folder, at the repo root). See the spec's "Corrected understanding" section for the source-level detail.

---

### Task 1: Fix the `category: link` typo

`_posts/2025-10-27-rattlesnake-kate.md` has `category: link` (singular) instead of `links`. This must be fixed before the move — otherwise the migration script in Task 3 would create a stray `link/_posts/` folder for this one post.

**Files:**
- Modify: `_posts/2025-10-27-rattlesnake-kate.md:5`

- [ ] **Step 1: Make the edit**

Change line 5 from:
```yaml
category: link
```
to:
```yaml
category: links
```

- [ ] **Step 2: Verify**

Run: `grep -c "^category: links$" _posts/2025-10-27-rattlesnake-kate.md`
Expected: `1`

Run: `grep -rc "^category: link$" _posts/ | grep -v ":0"`
Expected: no output

- [ ] **Step 3: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave this as an unstaged working-tree modification.

---

### Task 2: Capture a pre-migration build baseline

This produces a full site build *before* any structural change, to diff against after the migration (Task 8). This is the closest thing to a regression test suite this static site has.

**Files:** none in the repo — this writes to a temp directory outside the working tree.

- [ ] **Step 1: Build the baseline**

```bash
bundle exec jekyll build --destination /tmp/irrelefante-baseline
```
Expected: build succeeds with no errors, ending in a line like `Done in N.NN seconds.` This takes 3-4 minutes (webmention/URL-metadata plugins do live network lookups) — **block on it until it finishes**, do not detach into the background and return early.

- [ ] **Step 2: Spot-check that sample posts exist at their current URLs**

```bash
test -f /tmp/irrelefante-baseline/textos/2024/01/18/30/index.html && echo "textos OK"
test -f /tmp/irrelefante-baseline/notas/2025/09/08/silksong/index.html && echo "notas OK"
test -f /tmp/irrelefante-baseline/links/2025/10/27/rattlesnake-kate/index.html && echo "links OK"
test -f /tmp/irrelefante-baseline/reviews/2023/10/20/super-mario-bros-wonder/index.html && echo "reviews OK"
```
Expected: all four `OK` lines print. (The reviews sample builds under `2023/10/20`, not `10/21` — its front-matter date is `2023-10-21 00:00 +0000`, and the site's `timezone: America/Sao_Paulo` config shifts it to Oct 20 for the permalink. This is expected, unrelated to the migration. The `links` check also confirms Task 1's typo fix took effect.)

- [ ] **Step 3: No commit**

This is a local reference artifact only, not part of the repository. Do not `git add` anything here.

---

### Task 3: Move posts into `<category>/_posts/` folders

**Files:**
- Move (via `git mv`): all 350 files currently in `_posts/*.md`, into `links/_posts/`, `notas/_posts/`, `textos/_posts/`, or `reviews/_posts/` (folders at the **repo root**, each containing its own `_posts` subdirectory) based on each file's current `category:` value.

- [ ] **Step 1: Run the move**

```bash
mkdir -p links/_posts notas/_posts textos/_posts reviews/_posts
cd _posts
for f in *.md; do
  cat_value=$(sed -n 's/^category: *//p' "$f" | head -1)
  case "$cat_value" in
    links)   git mv "$f" "../links/_posts/$f" ;;
    notas)   git mv "$f" "../notas/_posts/$f" ;;
    textos)  git mv "$f" "../textos/_posts/$f" ;;
    reviews) git mv "$f" "../reviews/_posts/$f" ;;
    *)
      echo "UNEXPECTED category '$cat_value' in $f" >&2
      exit 1
      ;;
  esac
done
cd ..
```
Expected: no `UNEXPECTED category` errors; the loop runs to completion. The old `_posts/` directory at the repo root will end up empty (git doesn't track empty directories, so it simply disappears from `git status`).

- [ ] **Step 2: Verify counts**

```bash
ls _posts/*.md 2>/dev/null | wc -l          # expect 0 (old flat _posts/ is now empty)
ls links/_posts/*.md | wc -l                # expect 143
ls notas/_posts/*.md | wc -l                # expect 132
ls textos/_posts/*.md | wc -l               # expect 40
ls reviews/_posts/*.md | wc -l              # expect 35
```
Expected: `0`, `143`, `132`, `40`, `35` respectively (sums to 350).

- [ ] **Step 3: Verify these were recorded as renames, not delete+add**

```bash
git status --porcelain | grep -v "^R  " | head -10
```
Expected: no output (every change is a clean rename — the one exception from a prior run, `_posts/2025-10-27-rattlesnake-kate.md` showing `RM` for a combined rename+content-edit, only applies if Task 1's edit is still unstaged at this point, which is expected and fine).

- [ ] **Step 4: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave everything staged (that's inherent to `git mv`) but uncommitted.

---

### Task 4: Drop the front-matter `category` field and fix `_config.yml`'s defaults

Two edits that must land together (both are needed for consistent category data — see the spec's rationale for why leaving either half undone breaks things).

**Files:**
- Modify: all 350 files under `links/_posts/`, `notas/_posts/`, `textos/_posts/`, `reviews/_posts/`
- Modify: `_config.yml:14-22`

- [ ] **Step 1: Strip the `category:` line from every post**

```bash
find links/_posts notas/_posts textos/_posts reviews/_posts -maxdepth 1 -name "*.md" -exec sed -i '/^category: /d' {} +
```

- [ ] **Step 2: Verify no `category:` front matter remains**

```bash
grep -rl "^category:" links/_posts notas/_posts textos/_posts reviews/_posts | wc -l
```
Expected: `0`

- [ ] **Step 3: Spot-check one file's front matter is still valid YAML**

```bash
sed -n '1,10p' notas/_posts/2025-09-08-silksong.md
```
Expected: a well-formed `---`-delimited front-matter block, with the `category:` line simply gone and `tags:` following directly after `date:`.

- [ ] **Step 4: Update `_config.yml`'s defaults block**

Change (around line 14-22):
```yaml
defaults:
- scope:
    path: "_posts"
    type: "posts"
  values:
    category: textos
    syndicate_to:
      - bluesky
      - mastodon
```
to:
```yaml
defaults:
- scope:
    type: "posts"
  values:
    syndicate_to:
      - bluesky
      - mastodon
```

Both the `category: textos` value line AND the `path: "_posts"` scope key are removed. The `path` key must go too — it's a plain prefix match against each document's relative path, and once posts live at `links/_posts/...` etc., none of their relative paths start with the literal string `_posts` anymore, so a lingering `path: "_posts"` scope would silently stop applying to *any* post, breaking the `syndicate_to` default for the whole site. Dropping `path` entirely makes the scope match on `type: "posts"` alone, which is location-independent.

- [ ] **Step 5: Verify**

```bash
grep -n "category: textos" _config.yml
grep -n 'path: "_posts"' _config.yml
```
Expected: no output from either command.

- [ ] **Step 6: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave this as an unstaged working-tree modification.

---

### Task 5: Update templates to read `categories` (plural) instead of `category` (singular)

Jekyll's directory-based categorization populates `page.categories` (an array), not the old custom `page.category` (a plain string) that the front-matter field used to provide. Since each post now lives in exactly one category folder, `categories` is always a single-element array — use `| first` where the old code read the value directly, and use `contains "reviews"` (exact array-element match) where the old code did a substring `contains "review"` check.

**Files:**
- Modify: `_layouts/post.html:5`
- Modify: `_includes/blog/post.html:1`
- Modify: `_includes/blog/review.html:3`
- Modify: `index.html:7`
- Modify: `_layouts/archive.html:25`

- [ ] **Step 1: `_layouts/post.html`**

Change line 5 from:
```liquid
<article class="post {{ page.category | slugify: 'latin' }} h-entry {% if page.category contains 'review' -%} h-review {%- endif -%}">
```
to:
```liquid
<article class="post {{ page.categories | first | slugify: 'latin' }} h-entry {% if page.categories contains 'reviews' -%} h-review {%- endif -%}">
```

- [ ] **Step 2: `_includes/blog/post.html`**

Change line 1 from:
```liquid
<article class="post {{ post.category | slugify: 'latin'}} h-entry">
```
to:
```liquid
<article class="post {{ post.categories | first | slugify: 'latin'}} h-entry">
```

- [ ] **Step 3: `_includes/blog/review.html`**

Change line 3 from:
```liquid
<article class="post {{ review_post.category | slugify: 'latin' }} h-entry h-review">
```
to:
```liquid
<article class="post {{ review_post.categories | first | slugify: 'latin' }} h-entry h-review">
```

- [ ] **Step 4: `index.html`**

Change line 7 from:
```liquid
    {% if post.category contains "review" -%}
```
to:
```liquid
    {% if post.categories contains "reviews" -%}
```

- [ ] **Step 5: `_layouts/archive.html`**

Change line 25 from:
```liquid
    {% if post.category contains "review" -%}
```
to:
```liquid
    {% if post.categories contains "reviews" -%}
```

- [ ] **Step 6: Verify no old singular usage remains**

```bash
grep -rnE "\.category\b" _layouts _includes index.html
```
Expected: no output. (This will not match the unrelated `p-category` microformat CSS class name in `_layouts/post.html`, `_includes/blog/review.html`, and `_includes/review-widget.html`, since there's a hyphen, not a dot, before `category` in that string.)

- [ ] **Step 7: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave everything unstaged.

---

### Task 6: Add category prefixes to in-content `post_url` references

Jekyll's `{% post_url %}` tag (used inside 31 post bodies to link to other posts) matches its target by relative path. Now that every post lives in a category folder, bare-slug references no longer resolve, and the site fails to build entirely:

```
Liquid Exception: Could not find post "2017-07-25-the-legend-of-zelda-breath-of-the-wild-é-um-jogo-monumental" in tag 'post_url'. Make sure the post exists and the name is correct.
```

Jekyll's `post_url` matcher (`lib/jekyll/tags/post_url.rb`) builds a regex `^_posts/<category>/<slug>\.[^.]+|^<category>/_posts/?<slug>\.[^.]+` from the tag's argument — a category-prefixed argument like `{% post_url reviews/<slug> %}` matches **either** the `_posts/<category>/` or `<category>/_posts/` layout, so this fix works regardless of which physical structure is chosen.

**Files:** 31 post files across all 4 category folders contain `post_url` references — 50 occurrences total, referencing 37 distinct target posts.

- [ ] **Step 1: Confirm current scope**

```bash
grep -rnoE '\{%[[:space:]]*post_url[[:space:]]+[^[:space:]%]+[[:space:]]*%\}' links/_posts notas/_posts textos/_posts reviews/_posts | wc -l
```
Expected: `50`

- [ ] **Step 2: Apply the fix**

One `sed` invocation, one substitution rule per distinct referenced slug (37 rules), each rule prefixing that slug with the category folder its target post now lives in:

```bash
find links/_posts notas/_posts textos/_posts reviews/_posts -maxdepth 1 -name "*.md" -exec sed -i \
  -e 's|{% post_url 2015-01-02-kentucky-route-zero-act-iii-destrói-sua-alma-com-dívidas-do-passado %}|{% post_url reviews/2015-01-02-kentucky-route-zero-act-iii-destrói-sua-alma-com-dívidas-do-passado %}|g' \
  -e 's|{% post_url 2016-01-15-animal-crossing-new-leaf-vai-vender-sua-alma-para-reformar-sua-casa %}|{% post_url reviews/2016-01-15-animal-crossing-new-leaf-vai-vender-sua-alma-para-reformar-sua-casa %}|g' \
  -e 's|{% post_url 2016-07-19-não-há-muito-o-que-dizer-sobre-esperando-godot %}|{% post_url reviews/2016-07-19-não-há-muito-o-que-dizer-sobre-esperando-godot %}|g' \
  -e 's|{% post_url 2017-07-25-the-legend-of-zelda-breath-of-the-wild-é-um-jogo-monumental %}|{% post_url reviews/2017-07-25-the-legend-of-zelda-breath-of-the-wild-é-um-jogo-monumental %}|g' \
  -e 's|{% post_url 2017-10-16-certas-mulheres %}|{% post_url reviews/2017-10-16-certas-mulheres %}|g' \
  -e 's|{% post_url 2019-02-07-o-passado-e-o-presente-se-confundem-em-the-suburbs %}|{% post_url reviews/2019-02-07-o-passado-e-o-presente-se-confundem-em-the-suburbs %}|g' \
  -e 's|{% post_url 2019-07-31-como-as-tirinhas-salvaram-a-minha-vida %}|{% post_url textos/2019-07-31-como-as-tirinhas-salvaram-a-minha-vida %}|g' \
  -e 's|{% post_url 2019-08-14-um-ranking-de-todos-os-super-mario %}|{% post_url textos/2019-08-14-um-ranking-de-todos-os-super-mario %}|g' \
  -e 's|{% post_url 2019-09-25-aprendendo-a-perder-com-pokémon-let-s-go-eevee %}|{% post_url reviews/2019-09-25-aprendendo-a-perder-com-pokémon-let-s-go-eevee %}|g' \
  -e 's|{% post_url 2020-05-05-foi-assim-que-fleabag-partiu-meu-coração %}|{% post_url reviews/2020-05-05-foi-assim-que-fleabag-partiu-meu-coração %}|g' \
  -e 's|{% post_url 2020-05-07-os-filmes-de-kelly-reichardt-oferecem-um-conforto-estranho-durante-a-quarentena %}|{% post_url textos/2020-05-07-os-filmes-de-kelly-reichardt-oferecem-um-conforto-estranho-durante-a-quarentena %}|g' \
  -e 's|{% post_url 2020-05-11-eu-jogo-animal-crossing-e-fico-pensando-no-futuro %}|{% post_url textos/2020-05-11-eu-jogo-animal-crossing-e-fico-pensando-no-futuro %}|g' \
  -e 's|{% post_url 2020-05-21-no-fim-das-contas-eu-me-reapaixonei-por-música-no-meio-de-tudo-isso %}|{% post_url textos/2020-05-21-no-fim-das-contas-eu-me-reapaixonei-por-música-no-meio-de-tudo-isso %}|g' \
  -e 's|{% post_url 2020-06-09-um-ranking-de-todos-os-the-legend-of-zelda %}|{% post_url textos/2020-06-09-um-ranking-de-todos-os-the-legend-of-zelda %}|g' \
  -e 's|{% post_url 2020-08-18-poucos-filmes-entendem-a-morte-tão-bem-quanto-a-rota-selvagem %}|{% post_url reviews/2020-08-18-poucos-filmes-entendem-a-morte-tão-bem-quanto-a-rota-selvagem %}|g' \
  -e 's|{% post_url 2020-10-13-talvez-eu-devesse-me-sentir-culpado-por-jogar-animal-crossing-esse-tempo-todo %}|{% post_url textos/2020-10-13-talvez-eu-devesse-me-sentir-culpado-por-jogar-animal-crossing-esse-tempo-todo %}|g' \
  -e 's|{% post_url 2020-10-15-os-contos-de-raymond-carver %}|{% post_url textos/2020-10-15-os-contos-de-raymond-carver %}|g' \
  -e 's|{% post_url 2020-10-27-kentucky-route-zero-chegou-ao-fim %}|{% post_url reviews/2020-10-27-kentucky-route-zero-chegou-ao-fim %}|g' \
  -e 's|{% post_url 2022-12-17-jennifer-egan-a-casa-de-doces %}|{% post_url reviews/2022-12-17-jennifer-egan-a-casa-de-doces %}|g' \
  -e 's|{% post_url 2023-02-02-ondas-de-memória-a-beleza-dilacerante-de-aftersun %}|{% post_url reviews/2023-02-02-ondas-de-memória-a-beleza-dilacerante-de-aftersun %}|g' \
  -e 's|{% post_url 2023-02-26-o-jogo-perfeito-para-esperar-pelo-novo-zelda %}|{% post_url reviews/2023-02-26-o-jogo-perfeito-para-esperar-pelo-novo-zelda %}|g' \
  -e 's|{% post_url 2023-07-01-showing-up %}|{% post_url reviews/2023-07-01-showing-up %}|g' \
  -e 's|{% post_url 2023-11-08-aftermath %}|{% post_url links/2023-11-08-aftermath %}|g' \
  -e 's|{% post_url 2023-12-29-as-cinco-melhores-coisas-de-2023 %}|{% post_url textos/2023-12-29-as-cinco-melhores-coisas-de-2023 %}|g' \
  -e 's|{% post_url 2024-07-03-delinha %}|{% post_url textos/2024-07-03-delinha %}|g' \
  -e 's|{% post_url 2024-09-24-clube-da-esquina-n2 %}|{% post_url notas/2024-09-24-clube-da-esquina-n2 %}|g' \
  -e 's|{% post_url 2024-12-14-a-sequência-de-trocas-de-link-s-awakening %}|{% post_url textos/2024-12-14-a-sequência-de-trocas-de-link-s-awakening %}|g' \
  -e 's|{% post_url 2024-12-19-as-cinco-melhores-coisas-de-2024 %}|{% post_url textos/2024-12-19-as-cinco-melhores-coisas-de-2024 %}|g' \
  -e 's|{% post_url 2025-01-13-ió %}|{% post_url textos/2025-01-13-ió %}|g' \
  -e 's|{% post_url 2025-05-06-últimas-memórias %}|{% post_url textos/2025-05-06-últimas-memórias %}|g' \
  -e 's|{% post_url 2025-08-12-meu-firefox %}|{% post_url textos/2025-08-12-meu-firefox %}|g' \
  -e 's|{% post_url 2025-08-16-minha-dieta-cultural-na-última-semana %}|{% post_url notas/2025-08-16-minha-dieta-cultural-na-última-semana %}|g' \
  -e 's|{% post_url 2025-08-25-desativando-notificações %}|{% post_url notas/2025-08-25-desativando-notificações %}|g' \
  -e 's|{% post_url 2025-08-27-vivi-cinco-anos-com-seis-anos-sem %}|{% post_url textos/2025-08-27-vivi-cinco-anos-com-seis-anos-sem %}|g' \
  -e 's|{% post_url 2025-08-30-minha-dieta-cultural-na-última-semana %}|{% post_url notas/2025-08-30-minha-dieta-cultural-na-última-semana %}|g' \
  -e 's|{% post_url 2025-10-16-the-mastermind %}|{% post_url reviews/2025-10-16-the-mastermind %}|g' \
  -e 's|{% post_url 2026-03-21-daguerreótipos %}|{% post_url reviews/2026-03-21-daguerreótipos %}|g' \
  {} +
```

- [ ] **Step 3: Verify no bare (unprefixed) `post_url` tags remain**

```bash
grep -rnoE '\{%[[:space:]]*post_url[[:space:]]+[^[:space:]%/]+[[:space:]]*%\}' links/_posts notas/_posts textos/_posts reviews/_posts | wc -l
```
Expected: `0`

- [ ] **Step 4: Verify all 50 occurrences now carry a valid category prefix**

```bash
grep -rnoE '\{%[[:space:]]*post_url[[:space:]]+(links|notas|textos|reviews)/[^[:space:]%]+[[:space:]]*%\}' links/_posts notas/_posts textos/_posts reviews/_posts | wc -l
```
Expected: `50`

- [ ] **Step 5: Spot-check the exact reference that broke the build in the earlier attempt**

```bash
git diff -- textos/_posts/2019-08-14-um-ranking-de-todos-os-super-mario.md
```
Expected: shows `{% post_url 2017-07-25-the-legend-of-zelda-breath-of-the-wild-é-um-jogo-monumental %}` changed to `{% post_url reviews/2017-07-25-the-legend-of-zelda-breath-of-the-wild-é-um-jogo-monumental %}`.

- [ ] **Step 6: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave everything unstaged.

---

### Task 7: Update the CI workflow and CMS config to the new file locations

**Files:**
- Modify: `.github/workflows/standard-site.yml`
- Modify: `.pages.yml:45`

- [ ] **Step 1: `.github/workflows/standard-site.yml`**

Change the trigger paths (line 6) from:
```yaml
    paths: ["_posts/**"]
```
to:
```yaml
    paths: ["links/_posts/**", "notas/_posts/**", "textos/_posts/**", "reviews/_posts/**"]
```

Change the commit step (lines 37, 40) from:
```yaml
          if [[ -n "$(git status --porcelain _posts)" ]]; then
            git config user.name "github-actions[bot]"
            git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
            git add _posts
```
to:
```yaml
          if [[ -n "$(git status --porcelain -- links/_posts notas/_posts textos/_posts reviews/_posts)" ]]; then
            git config user.name "github-actions[bot]"
            git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
            git add links/_posts notas/_posts textos/_posts reviews/_posts
```

- [ ] **Step 2: `.pages.yml`**

Change line 45 from:
```yaml
      path: _posts/links
```
to:
```yaml
      path: links/_posts
```

- [ ] **Step 3: Verify**

```bash
grep -n "_posts" .github/workflows/standard-site.yml
grep -n "path: links/_posts" .pages.yml
```
Expected: the workflow grep shows only the 4 new category-qualified paths (no bare `_posts` left); the `.pages.yml` grep shows exactly one match.

- [ ] **Step 4: Commit**

Per the safety note at the top of this plan: do NOT run `git commit`. Leave everything unstaged.

---

### Task 8: Rebuild and diff against the baseline

This is the acceptance check for the whole migration: the post-migration site output should be identical to the Task 2 baseline, with one known, harmless exception (`feed.xml`'s top-level `<updated>` timestamp reflects each build's wall-clock time regardless of any content change).

**Files:** none in the repo — this reads the Task 2 baseline and writes another temp directory.

- [ ] **Step 0: Confirm no stray build processes are already running**

```bash
tasklist //FI "IMAGENAME eq ruby.exe" 2>/dev/null
```
If any `ruby.exe` process is listed, stop and report this to the controller before proceeding — do not kill it yourself and do not build on top of an unknown concurrent process. (This check exists because a prior attempt at this exact task left an orphaned build process running, which caused a corrupted build on the next attempt.)

- [ ] **Step 1: Build after migration**

```bash
bundle exec jekyll build --destination /tmp/irrelefante-after
```
Expected: build succeeds with no errors. This takes 3-4 minutes — **block on it until it finishes**. Do not detach into the background; do not report completion until you have the actual exit status and output in hand.

- [ ] **Step 2: Diff everything except the one known timestamp-dependent file**

```bash
diff -rq -x feed.xml /tmp/irrelefante-baseline /tmp/irrelefante-after
```
Expected: no output at all (zero differences). **Critically:** verify that `links/`, `notas/`, `textos/`, and `reviews/` each still appear as top-level directories in `/tmp/irrelefante-after` (`ls /tmp/irrelefante-after`) — their absence is exactly the failure mode of the disproven `_posts/<category>/` layout from an earlier attempt, and would mean categories are not being derived at all.

- [ ] **Step 3: Confirm the `feed.xml` diff is exactly the expected timestamp line**

```bash
diff /tmp/irrelefante-baseline/feed.xml /tmp/irrelefante-after/feed.xml
```
Expected: exactly one pair of changed lines, both matching `<updated>...</updated>` as the very first `<updated>` tag in the file.

- [ ] **Step 4: Re-run the sample URL spot-check from Task 2 against the new build**

```bash
test -f /tmp/irrelefante-after/textos/2024/01/18/30/index.html && echo "textos OK"
test -f /tmp/irrelefante-after/notas/2025/09/08/silksong/index.html && echo "notas OK"
test -f /tmp/irrelefante-after/links/2025/10/27/rattlesnake-kate/index.html && echo "links OK"
test -f /tmp/irrelefante-after/reviews/2023/10/20/super-mario-bros-wonder/index.html && echo "reviews OK"
```
Expected: all four `OK` lines print, at the same paths as the baseline.

- [ ] **Step 5: Clean up the temp builds**

```bash
rm -rf /tmp/irrelefante-baseline /tmp/irrelefante-after
```

- [ ] **Step 6: Confirm no stray build processes remain**

```bash
tasklist //FI "IMAGENAME eq ruby.exe" 2>/dev/null
```
Expected: no ruby.exe processes listed. If any are found, report it — do not assume they're harmless.

- [ ] **Step 7: No commit**

Nothing in the repo changed in this task — it's verification only.

---

## Summary of commits

None are made during this execution pass — every task explicitly holds off on `git commit` per the safety note at the top of this plan. When the migration is later approved for commit, the natural commit boundaries are:

1. `fix(content): correct category typo (link -> links) on rattlesnake-kate post` (Task 1)
2. `content: move posts into <category>/_posts/ folders at the repo root` (Task 3)
3. `content: derive post category from folder instead of front matter` (Task 4)
4. `templates: read page.categories instead of the removed page.category field` (Task 5)
5. `content: prefix in-content post_url references with their target's category folder` (Task 6)
6. `ci: update workflow trigger paths and Pages CMS collection path for the new post locations` (Task 7)

(Task 2 and Task 8 produce no commits — they're the baseline-capture and verification steps around the actual changes.)
