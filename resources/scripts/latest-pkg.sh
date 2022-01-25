#!/bin/sh

[ -z "$1" ] && echo "Need a project ID to check" && exit 1

curl -s -o - https://gitlab.com/api/v4/projects/"$1"/packages | xargs | tr ',' '\n' | grep version | sed "s/v.*n.//" | sort | tail -n1
