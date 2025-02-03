#!/bin/sh
set -e

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# User config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
: "${ALPINE_BRANCH:="v3.21"}"
: "${ALPINE_MIRROR:="https://dl-cdn.alpinelinux.org/alpine"}"

: "${DEFAULT_TIMEZONE:="Etc/UTC"}"
: "${DEFAULT_HOSTNAME:="alpine"}"
: "${DEFAULT_ROOT_PASSWORD:="alpine"}"
: "${DEFAULT_DROPBEAR_ENABLED:="true"}"
: "${DEFAULT_KERNEL_MODULES:=""}"
: "${DEFAULT_SERVICES:="hostname local modules networking ntpd syslog"}"
: "${SYSINIT_SERVICES:="rngd"}"
: "${UBOOT_COUNTER_RESET_ENABLED:="true"}"
: "${UBOOT_PACKAGE:=""}"
# Project ID for raspi-alpine/crosscompile-uboot
: "${UBOOT_PROJ_ID:=$DEFAULT_UBOOT_PROJ_ID}"
: "${UBOOT_VERSION:=""}"
: "${ARCH:="aarch64"}"
: "${RPI_FIRMWARE_BRANCH:="alpine"}"
: "${RPI_FIRMWARE_GIT:="https://github.com/raspberrypi/firmware"}"
: "${CMDLINE:="console=serial0,115200 console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait quiet"}"
: "${DEV:="mdev"}"

: "${SIZE_BOOT:="100M"}"
: "${SIZE_ROOT_FS:="100M"}"
: "${SIZE_ROOT_PART:="500M"}"
: "${SIZE_DATA:="20M"}"
: "${IMG_NAME:="sdcard"}"

: "${OUTPUT_PATH:="/output"}"
: "${INPUT_PATH:="/input"}"
: "${CACHE_PATH:=""}"
: "${CUSTOM_IMAGE_SCRIPT:="image.sh"}"
: "${SIMPLE_IMAGE:=""}"

: "${STAGES:="00 10 20 30 40 50 60 70 80 90"}"

# alpine 3.19 and later only have linux-rpi not linux-rpi4 etc
ALPINE_BRANCH=$(echo $ALPINE_BRANCH | sed '/^[0-9]/s/^/v/')
COMP="3.19
${ALPINE_BRANCH#v}"

if [ "$ALPINE_BRANCH" != "edge" ]; then
  [ "$COMP" != "$(echo "$COMP" | sort -V)" ] && export OLDKERNEL="yes"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# static config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
WORK_PATH="/work"
IMAGE_PATH="${WORK_PATH}/img"
export RES_PATH=/resources/
DEF_STAGE_PATH="${RES_PATH}/scripts/stages"
export INPUT_PATH
export ROOTFS_PATH="${WORK_PATH}/root_fs"
export BOOTFS_PATH="${WORK_PATH}/boot_fs"
[ -z "${SIMPLE_IMAGE}" ] && export DATAFS_PATH="${WORK_PATH}/data_fs"
# shellcheck disable=SC2034
[ -z "${SIMPLE_IMAGE}" ] && SETUP_PREFIX="/data"

# console colours (default Green)
# shellcheck disable=SC2034
Red='-Red'
# shellcheck disable=SC2034
Yellow='-Yellow'
Blue='-Blue'
#Purple='-Purple'
Cyan='-Cyan'
#White='-White'

# ensure work directory is clean
rm -rf ${WORK_PATH:?}/*

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

make_image() {
  [ -d /tmp/genimage ] && rm -rf /tmp/genimage
  genimage --rootpath "$1" \
    --tmppath /tmp/genimage \
    --inputpath ${IMAGE_PATH} \
    --outputpath ${IMAGE_PATH} \
    --config "$2"
}

# run stage scripts
run_stage_scripts() {
  _srun=""
  for S in "${DEF_STAGE_PATH}/$1"/*.sh; do
    _sname=$(basename "$S")
    [ "$_sname" = "*.sh" ] && break
    colour_echo "  Stage $1 Found $_sname" "$Cyan"
    if [ -f ${INPUT_PATH}/stages/"$1"/"$_sname" ]; then
      colour_echo "  Overriding $1 $_sname with user version" "$Blue"
      # shellcheck disable=SC1090
      . ${INPUT_PATH}/stages/"$1"/"$_sname"
      _srun="$_srun $_sname"
    else
      # shellcheck disable=SC1090
      . "$S"
    fi
  done
  # run remaining user stage scripts
  colour_echo "  Running user Stage $1 scripts" "$Cyan"
  for S in "${INPUT_PATH}/stages/$1"/*.sh; do
    _sname=$(basename "$S")
    [ "$_sname" = "*.sh" ] && break
    if ! echo "$_srun" | grep -q "$_sname"; then
      colour_echo "  Found $_sname" "$Cyan"
      # shellcheck disable=SC1090
      . "$S"
    fi
  done
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stage 00 - Prepare root FS
# Stage 10 - Configure root FS
# Stage 20 - Configure system
# Stage 30 - Install extras
# Stage 40 - Kernel and u-boot
# Stage 50 - Configure boot FS
# Stage 60 - Running user image.sh script and user stage 6 scripts
# Stage 70 - Pruning kernel modules
# Stage 80 - Cleanup
# Stage 90 - Create SD card image
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for _stage in ${STAGES}; do
  run_stage_scripts "$_stage"
done
colour_echo ">> Finished <<"
