#!/bin/bash

set -e

bundle exec rake db:waiting_for_sessions_table
bundle exec rake db:migrate

exec "$@"
