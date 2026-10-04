FROM ruby:3.3.4

# install node & yarn
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt update \
 && apt install -y --fix-missing --no-install-recommends \
      nodejs \
      yarn \
      graphviz \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# use jemalloc2 instead of glibc malloc
RUN apt update \
 && apt install libjemalloc2 patchelf \
 && patchelf --add-needed libjemalloc.so.2 /usr/local/bin/ruby \
 && apt purge patchelf -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
WORKDIR /frontend

ENV PATH="/frontend/.bundle/bin:${PATH}"

COPY docker/development/bundle_install /usr/bin/bundle_install
COPY docker/development/entrypoint.sh /usr/bin/docker-entrypoint.sh
COPY docker/development/entrypoint-wait.sh /usr/bin/docker-entrypoint-wait.sh
RUN chmod +x /usr/bin/bundle_install \
 && chmod +x /usr/bin/docker-entrypoint*.sh
ENTRYPOINT ["docker-entrypoint.sh"]
