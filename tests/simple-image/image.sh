#!/bin/sh

# check net and apk working in build environment (installs inside build environment)
apk add --no-cache pebble

# check net and apk working inside chroot
# add extra packages inside chroot so correct arch and destination is used
# dropbear-scp is needed to use scp with dropbear
chroot_exec apk add dropbear-scp python3 tailscale

install "$INPUT_PATH"/hello.sh "$ROOTFS_PATH"/etc/local.d/hello.start

# load i2c module
echo 'i2c-dev' >"$ROOTFS_PATH"/etc/modules-load.d/i2c.conf

# load wifi module
echo "brcmfmac" >>"$ROOTFS_PATH"/etc/modules
