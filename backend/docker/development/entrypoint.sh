#!/bin/bash

set -e

mkdir -p tmp && touch tmp/entrypoint.lock

last_timestamp=`cat tmp/Gemfile.timestamp 2> /dev/null || echo ""`
current_timestamp=`stat -c %y Gemfile Gemfile.lock | sort | tail -n 1`

if [ "$last_timestamp" != "$current_timestamp" ]; then
  bundle_install
  stat -c %y Gemfile Gemfile.lock | sort | tail -n 1 > tmp/Gemfile.timestamp
fi

if [ ! -f 'tmp/db_created' ]; then
  echo "create database"
  RAILS_ENV=development bundle exec rake db:create
  if [ "$RAILS_ENV" != "test" ]; then
    bundle exec rake db:migrate
    if [ "$DYNAMO_DB_SEED" != "false" ]; then
      echo "seeding database"
      bundle exec rake db:seed
    fi
    touch tmp/db_created
  fi
fi

rm -f tmp/entrypoint.lock

if [ "$1" == "bash" ]; then
  # replacement doesn't work with bash -c "..." so exec directly
  exec "$@"
else
  # replace /backend/ by ./
  s=$(echo $@ | sed -e "s/^\.\/backend\//\.\//g" -e "s/^backend\//\.\//g")
  exec $s
fi
