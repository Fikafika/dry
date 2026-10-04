FROM ruby:3.3.4

ENV RAILS_ENV=production

RUN apt update \
 && apt-get install -y --fix-missing --no-install-recommends \
      net-tools \
      less \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# use jemalloc2 instead of glibc malloc
RUN apt update \
 && apt install libjemalloc2 patchelf \
 && patchelf --add-needed libjemalloc.so.2 /usr/local/bin/ruby \
 && apt purge patchelf -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

ENV RUBY_YJIT_ENABLE=1

# docker entrypoint
COPY ./docker/production/entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
WORKDIR /backend

# user
ARG APP_USER=deployer
ARG APP_GROUP=deployer
RUN addgroup --gid 102 --system $APP_GROUP && adduser --uid 101 --system --shell /sbin/nologin --no-create-home --ingroup $APP_GROUP $APP_USER && chown $APP_USER:$APP_GROUP /backend
USER $APP_USER

# bundle
ENV HOME=/backend BUNDLE_PATH=/backend/.bundle BUNDLE_BIN=/backend/.bundle/bin GEM_HOME=/backend/.bundle
COPY --chown=$APP_USER:$APP_GROUP ./Gemfile ./Gemfile.lock ./
ARG BUNDLE_JOBS=10
RUN /bin/bash -c 'bundle config set deployment "true" && bundle config set without development test && bundle install --jobs=$BUNDLE_JOBS'

COPY --chown=$APP_USER:$APP_GROUP docker/production/puma.rb docker/production/database.yml docker/production/sidekiq.yml docker/production/cable.yml docker/production/secrets.yml ./config/

# Copy the main application.
COPY --chown=$APP_USER:$APP_GROUP . ./

# APP_PATH_PREFIX
ARG APP_PATH_PREFIX
ENV APP_PATH_PREFIX=${APP_PATH_PREFIX}

# volumes
RUN mkdir -p /backend/tmp/pids /backend/log /backend/storage /backend/imports
VOLUME /backend/log /backend/storage /backend/imports

ENTRYPOINT ["docker-entrypoint.sh"]

#CMD bundle exec puma -C /backend/config/puma.rb
