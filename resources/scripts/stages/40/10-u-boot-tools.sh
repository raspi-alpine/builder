#!/bin/sh

[ -n "${SIMPLE_IMAGE}" ] && exit

# u-boot tools
install /uboot_tool ${ROOTFS_PATH}/usr/sbin/uboot_tool

if [ "$UBOOT_COUNTER_RESET_ENABLED" = "true" ]; then
  # mark system as booted (should be moved to application)
  install ${RES_PATH}/scripts/99-uboot.sh ${ROOTFS_PATH}/etc/local.d/99-uboot.start
fi
