# syntax=docker/dockerfile:experimental
FROM ruby:2.7.2-alpine

ENV RUNTIME_PACKAGES="linux-headers libxml2-dev make gcc libc-dev nodejs tzdata postgresql-dev postgresql git g++" \
    DEV_PACKAGES="build-base curl-dev" \
    HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES}

RUN adduser --uid 1000 -S rails
RUN mkdir /app && chown rails /app
USER rails

WORKDIR /app

COPY --chown=rails Gemfile Gemfile.lock /app/

RUN gem install bundler

RUN bundle config set app_config .bundle
RUN bundle config set path .cache/bundle
RUN --mount=type=cache,uid=1000,target=/app/.cache/bundle \
    bundle && \
    mkdir -p vendor && \
    cp -ar .cache/bundle vendor/bundle
RUN bundle config set path vendor/bundle

COPY --chown=rails . /app

RUN --mount=type=cache,uid=1000,target=/app/tmp/cache bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bin/rails", "s", "-b", "0.0.0.0"]

USER root
RUN apk del build-dependencies

