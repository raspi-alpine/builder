 #!/bin/bash
set -e

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# User config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
: ${ALPINE_BRANCH:="3.10"}
: ${ALPINE_MIRROR:="http://dl-cdn.alpinelinux.org/alpine"}

: ${TIME_ZONE:="Etc/UTC"}
: ${HOST_NAME:="alpine"}
: ${ROOT_PASSWORD:="alpine"}
: ${IMG_NAME:="alpine-${ALPINE_BRANCH}-sdcard.img"}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# static config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
RES_PATH=/resources/
BASE_PACKAGES="alpine-base tzdata parted ifupdown e2fsprogs-extra util-linux coreutils linux-rpi2"

WORK_PATH="/work"
OUTPUT_PATH="/output"
ROOTFS_PATH="${WORK_PATH}/root_fs"
BOOTFS_PATH="${WORK_PATH}/boot_fs"
DATAFS_PATH="${WORK_PATH}/data_fs"
IMAGE_PATH="${WORK_PATH}/img"


# ensure work directory is clean
rm -rf ${WORK_PATH}/*

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

chroot_exec() {
    chroot "${ROOTFS_PATH}" "$@" 1>&2
}

make_image() {
    [ -d /tmp/genimage ] && rm -rf /tmp/genimage
    genimage --rootpath $1 \
      --tmppath /tmp/genimage \
      --inputpath ${IMAGE_PATH} \
      --outputpath ${IMAGE_PATH} \
      --config $2
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create root FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Prepare root FS"

# update local repositories to destination ones to ensure the right packages where installed
cat >/etc/apk/repositories <<EOF
${ALPINE_MIRROR}/v${ALPINE_BRANCH}/main
${ALPINE_MIRROR}/v${ALPINE_BRANCH}/community
EOF

# copy apk keys to new root (required for initial apk add run)
mkdir -p ${ROOTFS_PATH}/etc/apk/keys/
cp /usr/share/apk/keys/*.rsa.pub ${ROOTFS_PATH}/etc/apk/keys/

# copy repositories to new root
cp /etc/apk/repositories ${ROOTFS_PATH}/etc/apk/repositories

# initial package installation
apk --root ${ROOTFS_PATH} --update-cache --initdb --arch armhf add $BASE_PACKAGES

# add google DNS to enable network access inside chroot
echo "nameserver 8.8.8.8" > ${ROOTFS_PATH}/etc/resolv.conf


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo ">> Configure root FS"

# set root password
chroot_exec passwd << EOF
${ROOT_PASSWORD}
${ROOT_PASSWORD}
EOF

# Set time zone
echo "${TIME_ZONE}" > ${ROOTFS_PATH}/etc/timezone
chroot_exec ln -fs /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

# Set host name
chroot_exec rc-update add hostname default
cat >${ROOTFS_PATH}/etc/hosts <<EOF
127.0.0.1   localhost ${HOST_NAME}
::1     localhost ${HOST_NAME}
EOF
cat >${ROOTFS_PATH}/etc/hostname <<EOF
${HOST_NAME}
EOF

# enable local startup files (stored in /etc/local.d/)
chroot_exec rc-update add local default
cat >${ROOTFS_PATH}/etc/conf.d/local <<EOF
rc_verbose=yes
EOF

# prepare network
chroot_exec rc-update add networking default
cat >${ROOTFS_PATH}/etc/network/interfaces <<EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# networking should not wait for local -> local brings up the interface
sed -i '/^\tneed/ s/$/ local/' ${ROOTFS_PATH}/etc/init.d/networking

# bring up eth0 on startup
cat >${ROOTFS_PATH}/etc/local.d/11-up_eth0.start <<EOF
#!/bin/sh
ifconfig eth0 up
EOF
chmod +x ${ROOTFS_PATH}/etc/local.d/11-up_eth0.start

# make root file system writeable 
cat >${ROOTFS_PATH}/etc/local.d/10-remount_root.start <<EOF
#!/bin/sh
mount -o remount,rw /
EOF
chmod +x ${ROOTFS_PATH}/etc/local.d/10-remount_root.start

# add script to resize data partition 
cp ${RES_PATH}/resizedata.sh ${ROOTFS_PATH}/etc/local.d/90-resizedata.start
chmod +x ${ROOTFS_PATH}/etc/local.d/90-resizedata.start

# mount data and boot partition (root is already mounted)
cat >${ROOTFS_PATH}/etc/fstab <<EOF
/dev/mmcblk0p1   /boot  vfat    defaults,ro    0       2
/dev/mmcblk0p3   /data  ext4    defaults       0       1
EOF

# custom
chroot_exec apk add dropbear
chroot_exec rc-update add dropbear


rm -rf ${ROOTFS_PATH}/var/cache/apk/*

# TODO /etc/motd


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create boot FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Configure boot FS"

# download base firmware
mkdir -p ${BOOTFS_PATH}
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/fixup_cd.dat
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/fixup_x.dat
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/start_cd.elf
wget -P ${BOOTFS_PATH} https://github.com/raspberrypi/firmware/raw/master/boot/start_x.elf

# copy linux kernel and overlays
cp ${ROOTFS_PATH}/usr/lib/linux-*-rpi2/*.dtb ${BOOTFS_PATH}/
cp -r ${ROOTFS_PATH}/usr/lib/linux-*-rpi2/overlays ${BOOTFS_PATH}/
cp ${ROOTFS_PATH}/boot/initramfs-rpi2 ${BOOTFS_PATH}/
cp ${ROOTFS_PATH}/boot/vmlinuz-rpi2 ${BOOTFS_PATH}/

# write boot config
cat >${BOOTFS_PATH}/config.txt <<EOF
disable_splash=1
boot_delay=0

gpu_mem=256
gpu_mem_256=64

hdmi_drive=1
hdmi_group=2
hdmi_mode=1
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0

[pi2]
kernel=vmlinuz-rpi2
initramfs initramfs-rpi2

[pi3]
kernel=vmlinuz-rpi2
initramfs initramfs-rpi2

[all]
include usercfg.txt

EOF

cat >${BOOTFS_PATH}/cmdline.txt <<EOF
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rw rootwait quiet

EOF

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create data FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Configure data FS"
mkdir -p ${DATAFS_PATH}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create image
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Create SD card image"

# boot partition
cat >${WORK_PATH}/genimage_boot.cfg <<EOF
image boot.vfat {
  name = "boot"
  vfat {
  }
  size = 32M
}
EOF
make_image ${BOOTFS_PATH} ${WORK_PATH}/genimage_boot.cfg

# root partition
cat >${WORK_PATH}/genimage_root.cfg <<EOF
image rootfs.ext4 {
  name = "root"
  ext4 {
  }
  size = 150MB
}
EOF
make_image ${ROOTFS_PATH} ${WORK_PATH}/genimage_root.cfg

# data partition
cat >${WORK_PATH}/genimage_data.cfg <<EOF
image datafs.ext4 {
  name = "data"
  ext4 {
  }
  size = 20MB
}
EOF
make_image ${DATAFS_PATH} ${WORK_PATH}/genimage_data.cfg

# sd card image
cat >${WORK_PATH}/genimage_sdcard.cfg <<EOF
image sdcard.img {
  hdimage {
  }

  partition boot {
    partition-type = 0xC
    bootable = "true"
    image = "boot.vfat"
  }

  partition rootfs {
    partition-type = 0x83
    image = "rootfs.ext4"
  }

  partition datafs {
    partition-type = 0x83
    image = "datafs.ext4"
  }
}
EOF
make_image ${IMAGE_PATH} ${WORK_PATH}/genimage_sdcard.cfg

# copy final image
cp ${IMAGE_PATH}/sdcard.img ${OUTPUT_PATH}/${IMG_NAME}
