#!/bin/sh

BASE_PACKAGES="alpine-base cloud-utils-growpart coreutils e2fsprogs-extra \
               ifupdown-ng mkinitfs partx rng-tools-extra tzdata util-linux"

# initial package installation
[ "$DEV" = "eudev" ] && BASE_PACKAGES="$BASE_PACKAGES eudev"
eval apk --root "$ROOTFS_PATH" --update-cache --initdb --keys-dir=/usr/share/apk/keys-stable --arch "$ARCH" add "$BASE_PACKAGES"

# stop initramfs creation as not used
echo "disable_trigger=\"YES\"" >${ROOTFS_PATH}/etc/mkinitfs/mkinitfs.conf