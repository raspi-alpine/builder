#!/bin/sh

# override default hdmi config
mkdir -p m4
echo "# this is included instead of default hdmi" > m4/hdmi.m4

docker run --pull always --rm -it -v "$PWD":/input -v "$PWD"/output:/output --env-file megaind.env ghcr.io/raspi-alpine/builder
