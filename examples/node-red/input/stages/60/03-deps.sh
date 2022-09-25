#!/bin/sh

# install deps and add avahi to default runlevel
chroot_exec apk add avahi dbus dropbear-scp htop npm python3 py3-smbus
chroot_exec rc-update add avahi-daemon default

# add deps needed for building
chroot_exec apk add --virtual .build-deps build-base linux-headers python3-dev py3-build py3-installer py3-setuptools py3-wheel

# set avahi name to DEFAULT_HOSTNAME value
sed "s/#host-name.*/host-name=${DEFAULT_HOSTNAME}/" -i "$ROOTFS_PATH"/etc/avahi/avahi-daemon.conf
