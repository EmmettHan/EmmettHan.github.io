# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Jekyll 4.0 personal blog ("Annan's Blog") using the "Moving" remote theme (`huangyz0918/moving`). Site: `https://annansuper.cn/`. Deployed via Netlify (DNS CNAME → `blog-annan.netlify.app`).

## Commands

```bash
bundle install            # Install Ruby dependencies (for local preview only)
bundle exec jekyll serve  # Local dev server at http://localhost:4000
bundle exec jekyll build  # Build static site into _site/

# Publish Obsidian notes to blog
./publish.sh /path/to/note.md                        # Generate to _posts/
./publish.sh /path/to/note.md --emoji 🔧 --tag Tools # With emoji tag format
./publish.sh /path/to/note.md --push                 # Generate + git push
```

`Gemfile.lock` is gitignored — dependencies resolve fresh each time.

## Architecture

**Theme override**: The repo uses `remote_theme` but fully overrides it with local files in `_layouts/`, `_includes/`, and `_sass/`. These shadow the upstream `huangyz0918/moving` theme. Changes to upstream won't appear unless you update local copies.

Key files:
- `_includes/head.html` — loads CSS (relative paths), highlight.js (deferred), GA (production only)
- `_layouts/post.html` — single post layout with MathJax
- `_layouts/home.html` — homepage, groups posts by year
- `assets/css/main.scss` — imports self-hosted Bitter font (not Google Fonts CDN)
- `_config.yml` — permalink: `/:year/:month/:day/:slug/` (matches Netlify pretty URLs)

**Content**: Posts in `_posts/` follow `YYYY-MM-DD-slug.md`. Title format: `emoji【tag】content` (e.g. `🔧【Crash】Crash排查指南`).

**publish.sh**: Python script that converts Obsidian notes to Jekyll posts. Handles:
- YAML `created` field → Jekyll `date`
- `[[wikilink]]` → plain text
- `> [!note]` callouts → blockquote
- Obsidian tag cleanup (`#AI生成` etc.)
- `![[image.png]]` → removed (MVP, no image upload yet)

## Deployment

Netlify auto-deploys on push to `main`. Permalink format in `_config.yml` is aligned with Netlify's pretty URLs (lowercase, no `.html`, trailing slash) to avoid 301 redirects.

## Performance Notes

CSS paths use relative (`/assets/css/main.css`) not absolute (`{{ site.url }}/...`). Bitter font is self-hosted in `assets/fonts/`. highlight.js loads with `defer`. All three were applied to fix ~2.5s white screen caused by Netlify TTFB + render-blocking resources.
