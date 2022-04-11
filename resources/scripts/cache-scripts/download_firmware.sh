#!/bin/sh -e

usage() {
  echo
  echo "Usage: download_firmare [-r REPO -b BRANCH]"
  echo "           defaults to raspberrypi stable branch"
  echo
  exit 1
}

RPI_FIRMWARE_BRANCH="stable"
RPI_FIRMWARE_GIT="https://github.com/raspberrypi/firmware"

while getopts "r:b:" OPTS; do
  case ${OPTS} in
    r) RPI_FIRMWARE_GIT=${OPTARG} ;;
    b) RPI_FIRMWARE_BRANCH=${OPTARG} ;;
    *) usage ;;
  esac
done

# download base firmware
colour_echo "   Getting firmware from ${RPI_FIRMWARE_BRANCH} branch" -Cyan

git clone "$RPI_FIRMWARE_GIT" --depth 1 \
  --branch "$RPI_FIRMWARE_BRANCH" --filter=blob:none \
  --sparse /tmp/firmware/
(
  cd /tmp/firmware/
  git sparse-checkout add boot/
  git checkout
)
