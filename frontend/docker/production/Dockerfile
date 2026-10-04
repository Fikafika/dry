FROM ruby:3.3.4

ENV RAILS_ENV=production NODE_ENV=production

# install node & yarn
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt update \
 && apt install -y --fix-missing --no-install-recommends \
      nodejs \
      yarn \
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

# docker entrypoint
COPY ./docker/production/entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
WORKDIR /frontend

# user
ARG APP_USER=deployer
ARG APP_GROUP=deployer
RUN addgroup --gid 102 --system $APP_GROUP && adduser --uid 101 --system --shell /sbin/nologin --no-create-home --ingroup $APP_GROUP $APP_USER && chown $APP_USER:$APP_GROUP /frontend
USER $APP_USER

# bundle
ENV HOME=/frontend BUNDLE_PATH=/frontend/.bundle BUNDLE_BIN=/frontend/.bundle/bin GEM_HOME=/frontend/.bundle
COPY --chown=$APP_USER:$APP_GROUP ./Gemfile ./Gemfile.lock ./
ARG BUNDLE_JOBS=10
RUN /bin/bash -c 'bundle config set deployment "true" && bundle config set without development test && bundle install --jobs=$BUNDLE_JOBS'

# yarn
COPY --chown=$APP_USER:$APP_GROUP ./package.json ./yarn.lock ./
RUN yarn config set registry "https://git.uneek.eu/verdaccio" && yarn install --frozen-lockfile && yarn cache clean

# production settings
COPY --chown=$APP_USER:$APP_GROUP docker/production/puma.rb docker/production/database.yml docker/production/cable.yml docker/production/secrets.yml ./config/

# Copy the main application.
COPY --chown=$APP_USER:$APP_GROUP . ./

# APP_PATH_PREFIX
ARG APP_PATH_PREFIX
ENV APP_PATH_PREFIX=${APP_PATH_PREFIX}

# assets
RUN bundle exec rake assets:precompile

# volumes
RUN mkdir -p /frontend/tmp/pids /frontend/log
VOLUME /frontend/log

ENTRYPOINT ["docker-entrypoint.sh"]

CMD bundle exec puma -C /frontend/config/puma.rb
