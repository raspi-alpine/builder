#!/bin/sh
set -e

#increase rootfs size to make room for python
docker run --rm -v "$PWD":/input -v "$PWD"/output/armv7:/output --env SIZE_ROOT_FS="0" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"

#build for armhf and aarch64 as well
docker run --rm -v "$PWD":/input -v "$PWD"/output/armhf:/output --env ARCH=armhf --env SIZE_ROOT_FS="150M" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"

# test hdmi include
mkdir -p m4
echo "# this is included instead of default hdmi" > m4/hdmi.m4
docker run --rm -v "$PWD":/input -v "$PWD"/output/aarch64:/output --env ARCH=aarch64 --env SIZE_ROOT_FS="150M" --env ALPINE_BRANCH="v3.14" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"
