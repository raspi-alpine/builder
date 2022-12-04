#!/bin/sh

# enable i2c
echo 'i2c-dev' >"$ROOTFS_PATH"/etc/modules-load.d/i2c.conf
echo 'dtparam=i2c_arm=on' >>"$BOOTFS_PATH"/config.txt
# add i2c and ttyAMA0 to mdev.conf
sed "/^fuse/ii2c-[0-9]       root:dialout 0660" -i "$ROOTFS_PATH"/etc/mdev.conf
sed "/ttyAMA0/ittyAMA0         root:dialout 0660" -i "$ROOTFS_PATH"/etc/mdev.conf

# enable hardware serial console
echo 'dtoverlay=miniuart-bt' >>"$BOOTFS_PATH"/config.txt

# start a login terminal on the serial port
#sed -e "s/#ttyS0/ttyAMA0/" -e "s/ttyS0/ttyAMA0/" -i "$ROOTFS_PATH"/etc/inittab

# needed for usb serial kernel modules
echo ftdi_sio >"$ROOTFS_PATH"/etc/modules-load.d/ftdi.conf
