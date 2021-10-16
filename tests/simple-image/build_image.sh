#!/bin/sh

docker run --rm -v "$PWD":/input -v "$PWD":/output "$CI_REGISTRY/$CI_PROJECT_PATH/$CI_COMMIT_BRANCH"