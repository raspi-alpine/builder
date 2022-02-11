#!/bin/sh
set -e

# get current partition index
current_idx=$(rdev | sed -E 's+.*p(.*)\s.*+\1+')

if [ "$current_idx" -eq 2 ]; then
    echo "Active partition: A"
else
    echo "Active partition: B"
fi
