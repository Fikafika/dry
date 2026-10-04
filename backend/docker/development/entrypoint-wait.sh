#!/bin/bash

set -e

if [ -f tmp/entrypoint.lock ]; then
  echo "waiting for backend_build"
fi

while [ -f tmp/entrypoint.lock ]; do
  sleep 1
done

if [ "$1" == "bash" ]; then
  # replacement doesn't work with bash -c "..." so exec directly
  exec "$@"
else
  # replace /backend/ by ./
  s=$(echo $@ | sed -e "s/^\.\/backend\//\.\//g" -e "s/^backend\//\.\//g")
  exec $s
fi
