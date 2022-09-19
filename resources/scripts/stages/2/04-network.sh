#!/bin/sh

# interface
# use hostname in /etc/hostname for dhcp
sed -E "s/eval echo .IF_DHCP_HOSTNAME/cat \/etc\/hostname/" -i ${ROOTFS_PATH}/usr/libexec/ifupdown-ng/dhcp

cat >${ROOTFS_PATH}/etc/network/interfaces.alpine-builder <<EOF2
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF2
cp ${ROOTFS_PATH}/etc/network/interfaces.alpine-builder ${DATAFS_PATH}/etc/network/interfaces

if [ -z "${SIMPLE_IMAGE}" ]; then
  # udhcpc & resolv.conf
  mkdir -p ${ROOTFS_PATH}/etc/udhcpc
  echo "RESOLV_CONF=/data/etc/resolv.conf" >${ROOTFS_PATH}/etc/udhcpc/udhcpc.conf
else
  rm ${ROOTFS_PATH}/etc/network/interfaces.alpine-builder
fi
