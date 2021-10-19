#!/bin/sh

#check net and apk working
#add extra packages inside chroot so correct arch is used
chroot_exec apk add --no-cache python3

install "$INPUT_PATH"/hello.sh "$ROOTFS_PATH"/etc/local.d/hello.start
