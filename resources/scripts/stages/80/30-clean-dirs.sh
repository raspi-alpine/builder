#!/bin/sh

(
  cd ${ROOTFS_PATH} || exit 1
  rm -rf tmp/*
  rm -rf var/cache/apk/* boot/initramfs* boot/System* boot/config* boot/dtbs-rpi*
  [ -z "${SIMPLE_IMAGE}" ] && rm -f boot/fixup*.dat boot/start*.elf boot/bootcode.bin
  if [ -n "${LIB_LOG}" ]; then
    cp -a var/lib var/log ${DATAFS_PATH}/var/
  fi
)
