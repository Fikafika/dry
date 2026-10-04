#!/bin/bash

set -e

bundle exec rake db:create
bundle exec rake db:migrate:with_data:concurrent_safe

if [ "$DYNAMO_DB_SEED" != "false" ]; then
  bundle exec rake db:seed
  touch tmp/db_seed
fi

exec "$@"
