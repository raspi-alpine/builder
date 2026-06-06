#!/bin/sh
set -e

cd "$(dirname "$0")"

usage() {
  echo
  echo "Usage: build_image.sh -i IMAGE [-f|-7|-8] [-p]"
  echo "           -i is the container image to use for the build"
  echo "           -p pulls newest version of the image before running"
  echo "           -f builds armhf section"
  echo "           -7 builds armv7 section"
  echo "           -8 builds armv8 (arm64) section"
  echo
  echo "           if -f -7 or -8 is not used all sections are built"
  exit 1
}

failed() {
  echo "--<< Failed on test: $1 >>--"
  exit 1
}

while getopts "i:f78p" OPTS; do
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

# use docker if it is running
if docker version; then
  RUNCOM=docker
else
  which container && RUNCOM=container
fi
if [ -z "$RUNCOM" ]; then
  echo "Need docker or container running to build image"
  exit 1
else
  echo "Using: $RUNCOM for build"
  echo
fi

mkdir -p output/aarch64-silent output/aarch64 cache
[ -n "$PULL" ] && "$RUNCOM" image pull "$IMG"

# shrink  rootfs size to minimum
if [ -n "$ARMV7" ]; then
  mkdir -p output/armv7
  "$RUNCOM" run --rm --cap-add SYS_ADMIN --cap-add NET_ADMIN \
    --mount type=bind,source="$PWD",target=/input \
    --mount type=bind,source="$PWD"/output/armv7,target=/output \
    --env ALPINE_BRANCH=3.14 --env UBOOT_VERSION=2022.04 --env SIZE_ROOT_FS="0" "$IMG" || failed "armv7"
fi

# build for armhf and set SIZE_ROOT_FS manually
if [ -n "$ARMHF" ]; then
  mkdir -p output/armhf
  "$RUNCOM" run --rm --cap-add SYS_ADMIN --cap-add NET_ADMIN \
    --mount type=bind,source="$PWD",target=/input \
    --mount type=bind,source="$PWD"/output/armhf,target=/output \
    --env ARCH=armhf --env SIZE_ROOT_FS="180M" --env ALPINE_BRANCH="edge" \
    --env ADDITIONAL_DIR_KERNEL_MODULES="w1" --env RPI_FIRMWARE_BRANCH="alpine" "$IMG" || failed "armhf"
fi

# test hdmi include, test env file with CMDLINE environment variable, test cache
if [ -n "$ARMV8" ]; then
  mkdir -p m4 output/aarch64-silent output/aarch64 cache
  echo "# this is included instead of default hdmi" >m4/hdmi.m4
  "$RUNCOM" run --rm --cap-add SYS_ADMIN --cap-add NET_ADMIN \
    --mount type=bind,source="$PWD",target=/input \
    --mount type=bind,source="$PWD"/output/aarch64-silent,target=/output \
    --mount type=bind,source="$PWD"/cache,target=/cache \
    --env-file=env-files/builder-silent.env "$IMG" || failed "aarch64-silent"
  "$RUNCOM" run --rm --cap-add SYS_ADMIN --cap-add NET_ADMIN \
    --mount type=bind,source="$PWD",target=/input \
    --mount type=bind,source="$PWD"/output/aarch64,target=/output \
    --mount type=bind,source="$PWD"/cache,target=/cache \
    --env-file=env-files/builder.env "$IMG" || failed "aarch64"
fi
