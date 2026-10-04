#!/bin/bash

set -e

if [ -f tmp/entrypoint.lock ]; then
  echo "waiting for frontend_build"
fi

while [ -f tmp/entrypoint.lock ]; do
  sleep 1
done

exec "$@"
