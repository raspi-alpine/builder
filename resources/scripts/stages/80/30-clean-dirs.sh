#!/bin/sh

(
  cd ${ROOTFS_PATH}
  rm -rf tmp/*
  rm -rf var/cache/apk/* boot/initramfs* boot/System* boot/config* boot/dtbs-rpi*
  [ -z "${SIMPLE_IMAGE}" ] && rm -f boot/fixup*.dat boot/start*.elf boot/bootcode.bin
)
