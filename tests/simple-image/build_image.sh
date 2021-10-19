#!/bin/sh

#increase rootfs size to make room for python
docker run --rm -v "$PWD":/input -v "$PWD"/output:/output --env SIZE_ROOT_FS="150M" "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_BRANCH"
