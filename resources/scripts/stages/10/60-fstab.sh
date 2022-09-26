#!/bin/sh

# install fstab
m4 -D xSIMPLEIMAGE=${SIMPLE_IMAGE} "$RES_PATH"/m4/fstab.m4 >${ROOTFS_PATH}/etc/fstab
