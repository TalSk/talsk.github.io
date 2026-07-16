# TalTechTreks

Source for my personal blog — reverse engineering, security, and side treks.

🔗 **[taltechtreks.com](https://taltechtreks.com)**

Built with [Jekyll](https://jekyllrb.com/) and the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme, deployed to GitHub Pages via GitHub Actions.

## Local development

### Option A: Docker (live reload)

**No need to rebuild for every change.** The site source is mounted into the container; Jekyll watches for changes and the browser auto-refreshes.

```bash
# One-time (or after changing Gemfile / Dockerfile)
docker compose build

# Start the site (includes drafts, livereload)
docker compose up
```

Open http://localhost:4000. Edit posts, drafts, `_config.yml`, or assets; the page rebuilds and refreshes. Stop with `Ctrl+C`.

### Option B: Ruby on your machine

Requires **Ruby 3.1 or 3.2** (Chirpy does not support Ruby 4.x) and **Bundler**.

```bash
# One-time: install gems
bundle install

# Start the site (includes drafts, livereload)
bundle exec jekyll serve --livereload --drafts
```

Open http://localhost:4000. On Windows, if file watching fails, add `--force_polling`.

When serving without `JEKYLL_ENV=production`, the plugin in `_plugins/dev_no_cache.rb` adds cache-busting params and a no-cache meta tag so a normal **F5** shows the latest content.

## License

- **Content** (posts, pages, original text and images) © Tal Skverer — see [`COPYRIGHT`](COPYRIGHT).
- **Theme:** [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) is used under the MIT License.
