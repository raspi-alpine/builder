#!/bin/sh

# override default hdmi config
mkdir -p input/m4
echo "# this is included instead of default hdmi" >input/m4/hdmi.m4

docker run --pull always --rm -it -v "$PWD"/input:/input -v "$PWD"/output:/output --env-file megaind.env ghcr.io/raspi-alpine/builder
