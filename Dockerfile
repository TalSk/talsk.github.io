# TalTechTreks - Chirpy Jekyll site
FROM ruby:3.2
WORKDIR /srv/jekyll

# Install dependencies from the committed lockfile so the image matches the
# Gemfile.lock that gets bind-mounted at runtime (otherwise bundler refuses to start).
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

# Copy site (including migrated _posts, _plugins, assets)
COPY . .

# So links use localhost when binding to 0.0.0.0
ENV JEKYLL_ENV=production
EXPOSE 4000
# With a volume mount (see docker-compose or -v), source is live; no rebuild needed for edits.
# --livereload: injects script to refresh browser on change
# --force_polling: required for file watching to work across bind mounts (e.g. Docker on Windows)
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--drafts", "--livereload", "--force_polling"]
