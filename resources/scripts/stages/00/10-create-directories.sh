#!/bin/sh

(
  mkdir -p ${BOOTFS_PATH}
  mkdir -p ${ROOTFS_PATH}
  cd ${ROOTFS_PATH} || exit 1
  mkdir -p proc sys tmp run dev/pts dev/shm etc/apk var/lock
  if [ -z "${SIMPLE_IMAGE}" ]; then
    mkdir -p data uboot ${DATAFS_PATH}/etc ${DATAFS_PATH}/root ${DATAFS_PATH}/etc/network
  fi
  if [ -n "${LIB_LOG}" ]; then
    mkdir -p ${DATAFS_PATH}/var/lib ${DATAFS_PATH}/var/log
  fi
  if [ -n "${OVERLAY}" ]; then
    mkdir -p ${DATAFS_PATH}/workdir
  fi
)
