#!/bin/sh

docker run --pull always --rm -it -v "$PWD"/input:/input -v "$PWD"/output:/output --env-file megaind.env ghcr.io/raspi-alpine/builder
