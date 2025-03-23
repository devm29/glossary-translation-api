# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.12

# ----------------------------------------------------------------- base stage
# The full Ruby image already carries the compilers and headers the native
# extensions need (bootsnap, msgpack, psych), so nothing is installed with apt.
FROM ruby:${RUBY_VERSION} AS base

ENV BUNDLE_PATH=/usr/local/bundle

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./

# ---------------------------------------------------------------- build stage
# Resolves the production bundle. None of the tooling reaches the runtime image.
FROM base AS builder

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test

RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .
RUN rm -rf spec

# Precompile the bootsnap cache so the first request does not pay for it.
RUN bundle exec bootsnap precompile --gemfile app/ config/ lib/

# ----------------------------------------------------------------- test stage
# Adds the development and test groups on top of the production bundle, and
# puts the specs back: `docker compose --profile test run --rm --build test`.
FROM builder AS test

ENV BUNDLE_WITHOUT="" \
    BUNDLE_WITH=development:test \
    RAILS_ENV=test

RUN bundle install
COPY spec spec

CMD ["sh", "-c", "bin/rails db:schema:load && bundle exec rspec && bundle exec standardrb"]

# -------------------------------------------------------------- runtime stage
# The pg gem ships its own libpq and the slim image has tzdata, so the runtime
# needs no extra packages either.
FROM ruby:${RUBY_VERSION}-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

RUN groupadd --system --gid 1000 rails \
 && useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /app

COPY --from=builder --chown=rails:rails "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=builder --chown=rails:rails /app /app

# tmp/ must be writable by the app user: Puma writes its pidfile there.
RUN mkdir -p tmp/pids log && chown -R rails:rails tmp log

USER rails

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD ["bin/healthcheck"]

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
