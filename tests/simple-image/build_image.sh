#!/bin/sh
set -e

usage()
{
  echo
  echo "Usage: build_image.sh -i IMAGE [-f|-7|-8] [-p]"
  echo "           -i is the docker image to use for the build"
  echo "           -p pulls newest version of the image before running"
  echo "           -f builds armhf section"
  echo "           -7 builds armv7 section"
  echo "           -8 builds arm8 (arm64) section"
  echo
  echo "           if -f -7 or -8 is not used all sections are built"
  exit 1
}

while getopts "i:f78p" OPTS
do
  case ${OPTS} in
    i) IMG=${OPTARG} ;;
    f) ARMHF="true" ;;
    7) ARMV7="true" ;;
    8) ARMV8="true" ;;
    p) PULL="true" ;;
    *) usage ;;
  esac
done

if [ -z "$ARMHF" ] && [ -z "$ARMV7" ] && [ -z "$ARMV8" ]; then
  ARMHF="true"
  ARMV7="true"
  ARMV8="true"
fi
[ -z "$IMG" ] && echo "Need an image to build with (-i)" && usage
[ -n "$PULL" ] && docker image pull "$IMG"

# shrink  rootfs size to minimum
if [ -n "$ARMV7" ]; then
  docker run --rm -v "$PWD":/input -v "$PWD"/output/armv7:/output \
    --env SIZE_ROOT_FS="0" "$IMG"
fi

# build for armhf and set SIZE_ROOT_FS manually
if [ -n "$ARMHF" ]; then
  docker run --rm -v "$PWD":/input -v "$PWD"/output/armhf:/output \
    --env ARCH=armhf --env SIZE_ROOT_FS="150M" --env ALPINE_BRANCH="edge" \
    --env ADDITIONAL_DIR_KERNEL_MODULES="w1" "$IMG"
fi

# test hdmi include, test env file with CMDLINE environment variable
if [ -n "$ARMV8" ]; then
  mkdir -p m4
  echo "# this is included instead of default hdmi" > m4/hdmi.m4
  docker run --rm -v "$PWD":/input -v "$PWD"/output/aarch64:/output \
    --env-file=builder.env "$IMG"
fi
