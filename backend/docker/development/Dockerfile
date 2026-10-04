FROM ruby:3.3.4

RUN apt update \
 && apt install -y --fix-missing --no-install-recommends \
     graphviz \
     net-tools \
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

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
WORKDIR /backend

ENV PATH="/backend/.bundle/bin:${PATH}"

COPY docker/development/bundle_install /usr/bin/bundle_install
COPY docker/development/entrypoint.sh /usr/bin/docker-entrypoint.sh
COPY docker/development/entrypoint-wait.sh /usr/bin/docker-entrypoint-wait.sh
RUN chmod +x /usr/bin/bundle_install \
 && chmod +x /usr/bin/docker-entrypoint*.sh
ENTRYPOINT ["docker-entrypoint.sh"]
