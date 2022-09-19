#!/bin/sh

# set host name
if [ -z "${SIMPLE_IMAGE}" ]; then
  echo "${DEFAULT_HOSTNAME}" >${ROOTFS_PATH}/etc/hostname.alpine-builder
  cp ${ROOTFS_PATH}/etc/hostname.alpine-builder ${DATAFS_PATH}/etc/hostname
else
  chroot_exec setup-hostname ${DEFAULT_HOSTNAME}
fi
