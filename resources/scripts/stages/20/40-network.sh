#!/bin/sh

# interface
# use hostname in /etc/hostname for dhcp
sed -E "s/eval echo .IF_DHCP_HOSTNAME/cat \/etc\/hostname/" -i ${ROOTFS_PATH}/usr/libexec/ifupdown-ng/dhcp

if [ -n "${OVERLAY}" ] || [ -n "${SIMPLE_IMAGE}" ]; then
  _interfaces=${ROOTFS_PATH}/etc/network/interfaces
else
  _interfaces=${DATAFS_PATH}/etc/network/interfaces
fi
cat >"$_interfaces" <<EOF2
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF2

if [ -z "${SIMPLE_IMAGE}" ] && [ -z "${OVERLAY}" ]; then
  cp ${DATAFS_PATH}/etc/network/interfaces ${ROOTFS_PATH}/etc/network/interfaces.alpine-builder
  # udhcpc & resolv.conf
  mkdir -p ${ROOTFS_PATH}/etc/udhcpc
  [ -z "${OVERLAY}" ] && echo "RESOLV_CONF=/data/etc/resolv.conf" >${ROOTFS_PATH}/etc/udhcpc/udhcpc.conf
fi
