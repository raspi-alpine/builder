#!/bin/sh

#increase rootfs size to make room for python
docker run --rm -v "$PWD":/input -v "$PWD"/output/armv7:/output --env SIZE_ROOT_FS="150M" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_BRANCH"

#build for armhf and aarch64 as well
docker run --rm -v "$PWD":/input -v "$PWD"/output/armhf:/output --env ARCH=armhf --env SIZE_ROOT_FS="150M" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_BRANCH"
docker run --rm -v "$PWD":/input -v "$PWD"/output/aarch64:/output --env ARCH=aarch64 --env SIZE_ROOT_FS="150M" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_BRANCH"
