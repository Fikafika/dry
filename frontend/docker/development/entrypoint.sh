#!/bin/bash

set -e

mkdir -p tmp && touch tmp/entrypoint.lock

last_timestamp=`cat tmp/Gemfile.timestamp 2> /dev/null || echo ""`
current_timestamp=`stat -c %y Gemfile Gemfile.lock | sort | tail -n 1`

if [ "$last_timestamp" != "$current_timestamp" ]; then
  bundle_install
  stat -c %y Gemfile Gemfile.lock | sort | tail -n 1 > tmp/Gemfile.timestamp
fi

last_timestamp=`cat tmp/package.json.timestamp 2> /dev/null || echo ""`
current_timestamp=`stat -c %y package.json yarn.lock | sort | tail -n 1`

if [ "$last_timestamp" != "$current_timestamp" ]; then
  yarn config set registry "https://git.uneek.eu/verdaccio"
  yarn install --non-interactive
  stat -c %y package.json yarn.lock | sort | tail -n 1 > tmp/package.json.timestamp
fi

if [ ! -f 'tmp/db_created' ]; then
  RAILS_ENV=development bundle exec rake db:create
  echo "waiting for sessions table"
  if [ "$RAILS_ENV" != "test" ]; then
    bundle exec rake db:waiting_for_sessions_table
    touch tmp/db_created
  fi
fi
if [ "$RAILS_ENV" = "test" ]; then
  SCHEMA=db/schema.backend.rb bundle exec rake db:schema:load
fi

rm -f tmp/entrypoint.lock

if [ "$1" == "bash" ]; then
  # replacement doesn't work with bash -c "..." so exec directly
  exec "$@"
else
  # replace /backend/ by ./
  s=$(echo $@ | sed -e "s/^\.\/frontend\//\.\//g" -e "s/^frontend\//\.\//g")
  exec $s
fi
