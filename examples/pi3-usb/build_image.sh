#!/bin/sh

docker run --rm -it -v "$PWD":/input -v "$PWD":/output --env SIZE_ROOT_FS=0 --env PI3USB="YES" ghcr.io/raspi-alpine/builder
