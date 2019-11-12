#!/bin/sh

cp ${INPUT_PATH}/app ${ROOTFS_PATH}/usr/bin/test_app
cp ${INPUT_PATH}/init.sh ${ROOTFS_PATH}/etc/init.d/test_app

chroot_exec rc-update add test_app default
