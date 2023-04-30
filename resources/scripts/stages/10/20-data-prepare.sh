#!/bin/sh

if [ -z "${SIMPLE_IMAGE}" ] && [ -z "${OVERLAY}" ]; then

  # prepare /data init script
  install ${RES_PATH}/scripts/data_prepare.sh ${ROOTFS_PATH}/etc/init.d/data_prepare
  DEFAULT_SERVICES="${DEFAULT_SERVICES} data_prepare"

fi
