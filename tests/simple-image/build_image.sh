#!/bin/sh
set -e

# shrink  rootfs size to minimum
docker run --rm -v "$PWD":/input -v "$PWD"/output/armv7:/output --env SIZE_ROOT_FS="0" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"

# build for armhf and aarch64 as well, set SIZE_ROOT_FS manually
docker run --rm -v "$PWD":/input -v "$PWD"/output/armhf:/output --env ARCH=armhf --env SIZE_ROOT_FS="150M" --env ALPINE_BRANCH="edge" --env ADDITIONAL_DIR_KERNEL_MODULES="w1" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"

# test hdmi include, test env file with CMDLINE environment variable
mkdir -p m4
echo "# this is included instead of default hdmi" > m4/hdmi.m4
docker run --rm -v "$PWD":/input -v "$PWD"/output/aarch64:/output --env-file=builder.env "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_REF_SLUG"
