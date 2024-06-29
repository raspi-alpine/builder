#!/bin/sh

# dropbear
chroot_exec apk add dropbear
chroot_exec rc-update add dropbear default

mv ${ROOTFS_PATH}/etc/conf.d/dropbear ${ROOTFS_PATH}/etc/conf.d/dropbear_org
ln -s /data/etc/dropbear/dropbear.conf ${ROOTFS_PATH}/etc/conf.d/dropbear

if [ "$DEFAULT_DROPBEAR_ENABLED" != "true" ]; then
  echo 'DROPBEAR_OPTS="-p 127.0.0.1:22"' >${ROOTFS_PATH}/etc/conf.d/dropbear_org
fi

if [ -z "$OVERLAY" ]; then
  _dest=${DATAFS_PATH}
else
  _dest=${ROOTFS_PATH}
fi
mkdir -p ${_dest}/etc/dropbear/
cp ${ROOTFS_PATH}/etc/conf.d/dropbear_org ${_dest}/etc/dropbear/dropbear.conf
