#!/bin/sh

# add script to resize data partition with init script
m4 -D xSIMPLEIMAGE=${SIMPLE_IMAGE} "$RES_PATH"/m4/ab_resizedata.sh.m4 >${WORK_PATH}/ab_resizedata.sh
install -D ${WORK_PATH}/ab_resizedata.sh ${ROOTFS_PATH}/sbin/ab_resizedata
install ${RES_PATH}/scripts/resize_last.sh ${ROOTFS_PATH}/etc/init.d/resize_last
install ${RES_PATH}/scripts/ab_bootparam.sh ${ROOTFS_PATH}/sbin/ab_bootparam

DEFAULT_SERVICES="${DEFAULT_SERVICES} resize_last"
