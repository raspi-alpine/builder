#!/bin/sh
set -e

# get current partition index
current_idx=$(ab_bootparam root | grep -Eo '[0-9]+$')

if [ "$current_idx" -eq 2 ]; then
  echo "Active partition: A"
else
  echo "Active partition: B"
fi
