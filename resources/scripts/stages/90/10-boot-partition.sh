#!/bin/sh

# boot partition
m4 -D xFS=vfat -D xIMAGE=boot.xFS -D xLABEL="BOOT" -D xSIZE="$SIZE_BOOT" \
  "$RES_PATH"/m4/genimage.m4 >"$WORK_PATH"/genimage_boot.cfg
make_image ${BOOTFS_PATH} ${WORK_PATH}/genimage_boot.cfg
