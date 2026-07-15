# Chirpy Starter

[![Gem Version](https://img.shields.io/gem/v/jekyll-theme-chirpy)][gem]&nbsp;
[![GitHub license](https://img.shields.io/github/license/cotes2020/chirpy-starter.svg?color=blue)][mit]

## Local development

### Option A: Docker (live reload)

**No need to rebuild for every change.** The repo is set up so the site source is mounted into the container; Jekyll watches for changes and the browser auto-refreshes.

```bash
# One-time (or after changing Gemfile / Dockerfile)
docker compose build

# Start the site (includes drafts, livereload)
docker compose up
```

Open http://localhost:4000. Edit posts, drafts, `_config.yml`, or assets; the page will rebuild and refresh. Stop with `Ctrl+C`.

### Option B: Without Docker (Ruby on your machine)

You need **Ruby 3.1 or 3.2** (Chirpy does not support Ruby 4.x) and **Bundler**.

- **Windows:** Install [Ruby 3.2](https://rubyinstaller.org/downloads/) (e.g. Ruby+Devkit 3.2.x). If you have multiple Ruby versions, use that installer’s terminal or ensure `ruby -v` shows 3.1 or 3.2 before running the commands below.
- **macOS/Linux:** Use `rbenv`, `rvm`, or your package manager to install Ruby 3.2, then run `ruby -v` to confirm.

```bash
# One-time: install gems
bundle install

# Start the site (includes drafts, livereload)
bundle exec jekyll serve --livereload --drafts
```

Open http://localhost:4000 (or http://127.0.0.1:4000). Edit posts, drafts, `_config.yml`, or assets; the page will rebuild and refresh. Stop with `Ctrl+C`.

When you run `jekyll serve` (without `JEKYLL_ENV=production`), the plugin in `_plugins/dev_no_cache.rb` adds cache-busting query params to asset URLs and a no-cache meta tag so a normal **F5** refresh shows the latest content.

On Windows, if file watching fails, add `--force_polling`:

```bash
bundle exec jekyll serve --livereload --drafts --force_polling
```

---

When installing the [**Chirpy**][chirpy] theme through [RubyGems.org][gem], Jekyll can only read files in the folders
`_data`, `_layouts`, `_includes`, `_sass` and `assets`, as well as a small part of options of the `_config.yml` file
from the theme's gem. If you have ever installed this theme gem, you can use the command
`bundle info --path jekyll-theme-chirpy` to locate these files.

The Jekyll team claims that this is to leave the ball in the user’s court, but this also results in users not being
able to enjoy the out-of-the-box experience when using feature-rich themes.

To fully use all the features of **Chirpy**, you need to copy the other critical files from the theme's gem to your
Jekyll site. The following is a list of targets:

```shell
.
├── _config.yml
├── _plugins
├── _tabs
└── index.html
```

## Usage

Check out the [theme's docs](https://github.com/cotes2020/jekyll-theme-chirpy/wiki).

## Contributing

This repository is automatically updated with new releases from the theme repository. If you encounter any issues or want to contribute to its improvement, please visit the [theme repository][chirpy] to provide feedback.

## License

This work is published under [MIT][mit] License.

[gem]: https://rubygems.org/gems/jekyll-theme-chirpy
[chirpy]: https://github.com/cotes2020/jekyll-theme-chirpy/
[CD]: https://en.wikipedia.org/wiki/Continuous_deployment
[mit]: https://github.com/cotes2020/chirpy-starter/blob/master/LICENSE

To save you time, and also in case you lose some files while copying, we extract those files/configurations of the
latest version of the **Chirpy** theme and the [CD][CD] workflow to here, so that you can start writing in minutes.
