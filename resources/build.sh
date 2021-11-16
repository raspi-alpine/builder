#!/bin/sh
set -e

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# User config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
: "${ALPINE_BRANCH:="v3.14"}"
: "${ALPINE_MIRROR:="https://dl-cdn.alpinelinux.org/alpine"}"

: "${DEFAULT_TIMEZONE:="Etc/UTC"}"
: "${DEFAULT_HOSTNAME:="alpine"}"
: "${DEFAULT_ROOT_PASSWORD:="alpine"}"
: "${DEFAULT_DROPBEAR_ENABLED:="true"}"
: "${DEFAULT_KERNEL_MODULES:="ipv6 af_packet rpi-poe-fan"}"
: "${UBOOT_COUNTER_RESET_ENABLED:="true"}"
: "${ARCH:="armv7"}"
: "${RPI_FIRMWARE_BRANCH:="stable"}"
: "${CMDLINE:="console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes ro rootwait quiet"}"

: "${SIZE_BOOT:="100M"}"
: "${SIZE_ROOT_FS:="100M"}"
: "${SIZE_ROOT_PART:="500M"}"
: "${SIZE_DATA:="20M"}"
: "${IMG_NAME:="sdcard"}"

: "${OUTPUT_PATH:="/output"}"
: "${INPUT_PATH:="/input"}"
: "${CUSTOM_IMAGE_SCRIPT:="image.sh"}"

ALPINE_BRANCH=$(echo $ALPINE_BRANCH | sed '/^[0-9]/s/^/v/')

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# static config
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
RES_PATH=/resources/
BASE_PACKAGES="alpine-base cloud-utils-growpart coreutils e2fsprogs-extra \
               ifupdown-ng mkinitfs partx rng-tools-extra tzdata util-linux"
WORK_PATH="/work"
ROOTFS_PATH="${WORK_PATH}/root_fs"
BOOTFS_PATH="${WORK_PATH}/boot_fs"
DATAFS_PATH="${WORK_PATH}/data_fs"
IMAGE_PATH="${WORK_PATH}/img"


# ensure work directory is clean
rm -rf ${WORK_PATH:?}/*

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

chroot_exec() {
    chroot "$ROOTFS_PATH" "$@" 1>&2
}

make_image() {
    [ -d /tmp/genimage ] && rm -rf /tmp/genimage
    genimage --rootpath "$1" \
      --tmppath /tmp/genimage \
      --inputpath ${IMAGE_PATH} \
      --outputpath ${IMAGE_PATH} \
      --config "$2"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# arch specific
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case "$ARCH" in
  armhf)   KERNEL_PACKAGES="linux-rpi linux-rpi2" ;;
  armv7)   KERNEL_PACKAGES="linux-rpi2 linux-rpi4" ;;
  aarch64) KERNEL_PACKAGES="linux-rpi4" ;;
esac

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create root FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Prepare root FS"

# update local repositories to destination ones to ensure the right packages where installed
cat >/etc/apk/repositories <<EOF
${ALPINE_MIRROR}/${ALPINE_BRANCH}/main
${ALPINE_MIRROR}/${ALPINE_BRANCH}/community
EOF

# copy repositories to new root
mkdir -p ${ROOTFS_PATH}/etc/apk
cp /etc/apk/repositories ${ROOTFS_PATH}/etc/apk/repositories

# initial package installation
eval apk --root "$ROOTFS_PATH" --update-cache --initdb --keys-dir=/usr/share/apk/keys --arch "$ARCH" add "$BASE_PACKAGES"
# Copy host's resolv config for building
cp -L /etc/resolv.conf ${ROOTFS_PATH}/etc/resolv.conf
# stop initramfs creation as not used
echo "disable_trigger=\"YES\"" > ${ROOTFS_PATH}/etc/mkinitfs/mkinitfs.conf
chroot_exec apk add --no-cache ${KERNEL_PACKAGES}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo ">> Configure root FS"

# Set time zone
ln -fs /data/etc/timezone ${ROOTFS_PATH}/etc/timezone
ln -fs /data/etc/localtime ${ROOTFS_PATH}/etc/localtime

# Set host name
chroot_exec rc-update add hostname default
ln -fs /data/etc/hostname ${ROOTFS_PATH}/etc/hostname

# enable local startup files (stored in /etc/local.d/)
chroot_exec rc-update add local default
cat >${ROOTFS_PATH}/etc/conf.d/local <<EOF
rc_verbose=yes
EOF

# prepare network
chroot_exec rc-update add networking default
ln -fs /data/etc/network/interfaces ${ROOTFS_PATH}/etc/network/interfaces
# use hostname in /etc/hostname for dhcp
sed -E "s/eval echo .IF_DHCP_HOSTNAME/cat \/etc\/hostname/" -i ${ROOTFS_PATH}/usr/libexec/ifupdown-ng/dhcp

# add script to resize data partition
install -D ${RES_PATH}/scripts/resizedata.sh ${ROOTFS_PATH}/sbin/ab_resizedata

# mount data and boot partition (root is already mounted)
cat >${ROOTFS_PATH}/etc/fstab <<EOF
none             /       ext4    defaults,ro    0       0
/dev/mmcblk0p1   /uboot  vfat    defaults,ro    0       2
/dev/mmcblk0p4   /data   ext4    defaults       0       1

proc           /proc        proc   defaults        0     0
sysfs          /sys         sysfs  defaults        0     0
devpts         /dev/pts     devpts gid=4,mode=620  0     0
tmpfs          /dev/shm     tmpfs  defaults        0     0
tmpfs          /tmp         tmpfs  defaults        0     0
tmpfs          /run         tmpfs  defaults        0     0
tmpfs          /var/lock    tmpfs  defaults        0     0
EOF

# prepare mount points
mkdir -p ${ROOTFS_PATH}/uboot
mkdir -p ${ROOTFS_PATH}/data
mkdir -p ${ROOTFS_PATH}/proc
mkdir -p ${ROOTFS_PATH}/sys
mkdir -p ${ROOTFS_PATH}/tmp
mkdir -p ${ROOTFS_PATH}/run
mkdir -p ${ROOTFS_PATH}/dev/pts
mkdir -p ${ROOTFS_PATH}/dev/shm
mkdir -p ${ROOTFS_PATH}/var/lock

# time
chroot_exec rc-update add ntpd default

# kernel modules
chroot_exec rc-update add modules default
echo "rpi-poe-fan" >> ${ROOTFS_PATH}/etc/modules

# rngd service for entropy
chroot_exec rc-update add rngd sysinit

# mdev service for device creation amd /dev/stderr etc
chroot_exec rc-update add mdev sysinit

# log to kernel printk buffer by default (read with dmesg)
chroot_exec rc-update add syslog default
echo "SYSLOGD_OPTS=\"-t -K\"" > ${ROOTFS_PATH}/etc/conf.d/syslog

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create data FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Configure data FS"
mkdir -p ${DATAFS_PATH}/etc

# set timezone
echo "${DEFAULT_TIMEZONE}" > ${ROOTFS_PATH}/etc/timezone.alpine-builder
cp ${ROOTFS_PATH}/etc/timezone.alpine-builder ${DATAFS_PATH}/etc/timezone
ln -fs /usr/share/zoneinfo/${DEFAULT_TIMEZONE} ${DATAFS_PATH}/etc/localtime

# set host name
echo "${DEFAULT_HOSTNAME}" > ${ROOTFS_PATH}/etc/hostname.alpine-builder
cp ${ROOTFS_PATH}/etc/hostname.alpine-builder ${DATAFS_PATH}/etc/hostname

# root password
root_pw=$(mkpasswd -m sha-512 -s "${DEFAULT_ROOT_PASSWORD}")
cp ${ROOTFS_PATH}/etc/shadow ${ROOTFS_PATH}/etc/shadow.alpine-builder
sed -i "/^root/d" ${ROOTFS_PATH}/etc/shadow.alpine-builder
echo "root:${root_pw}:0:0:::::" >> ${ROOTFS_PATH}/etc/shadow.alpine-builder
cp ${ROOTFS_PATH}/etc/shadow.alpine-builder ${DATAFS_PATH}/etc/shadow

# interface
cat > ${ROOTFS_PATH}/etc/network/interfaces.alpine-builder <<EOF2
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF2
mkdir -p ${DATAFS_PATH}/etc/network
cp ${ROOTFS_PATH}/etc/network/interfaces.alpine-builder ${DATAFS_PATH}/etc/network/interfaces

# root folder
mkdir -p ${DATAFS_PATH}/root/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# uboot tools
install /uboot_tool ${ROOTFS_PATH}/sbin/uboot_tool

if [ "$UBOOT_COUNTER_RESET_ENABLED" = "true" ]; then
  # mark system as booted (should be moved to application)
  install ${RES_PATH}/scripts/99-uboot.sh ${ROOTFS_PATH}/etc/local.d/99-uboot.start
fi

# copy helper scripts
install ${RES_PATH}/scripts/ab_active.sh ${ROOTFS_PATH}/sbin/ab_active
install ${RES_PATH}/scripts/ab_flash.sh ${ROOTFS_PATH}/sbin/ab_flash

# dropbear
chroot_exec apk add dropbear
chroot_exec rc-update add dropbear default
mkdir -p ${DATAFS_PATH}/etc/dropbear/
ln -s /data/etc/dropbear/ ${ROOTFS_PATH}/etc/dropbear

mv ${ROOTFS_PATH}/etc/conf.d/dropbear ${ROOTFS_PATH}/etc/conf.d/dropbear_org
ln -s /data/etc/dropbear/dropbear.conf ${ROOTFS_PATH}/etc/conf.d/dropbear

if [ "$DEFAULT_DROPBEAR_ENABLED" != "true" ]; then
  echo 'DROPBEAR_OPTS="-p 127.0.0.1:22"' > ${ROOTFS_PATH}/etc/conf.d/dropbear_org
fi

cp ${ROOTFS_PATH}/etc/conf.d/dropbear_org ${DATAFS_PATH}/etc/dropbear/dropbear.conf

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo ">> Move persistent data to /data"

# prepare /data
install ${RES_PATH}/scripts/data_prepare.sh ${ROOTFS_PATH}/etc/init.d/data_prepare
chroot_exec rc-update add data_prepare default

# link root dir
rmdir ${ROOTFS_PATH}/root
ln -s /data/root ${ROOTFS_PATH}/root

# udhcpc & resolv.conf
mkdir -p ${ROOTFS_PATH}/etc/udhcpc
cat >${ROOTFS_PATH}/etc/udhcpc/udhcpc.conf <<EOF
RESOLV_CONF=/data/etc/resolv.conf

EOF

# root password
ln -fs /data/etc/shadow ${ROOTFS_PATH}/etc/shadow

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo ">> Prepare kernel for uboot"

# build uImage

# uImage2 is for armhf and armv7 only
if [ "$ARCH" != "aarch64" ]; then
  mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux kernel" \
   -d "$ROOTFS_PATH"/boot/vmlinuz-rpi2 "$ROOTFS_PATH"/boot/uImage2
fi

# there is no uImage4 in armhf
A=arm
case "$ARCH" in
  armhf)   mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux kernel" \
            -d "$ROOTFS_PATH"/boot/vmlinuz-rpi "$ROOTFS_PATH"/boot/uImage
           sed "s/uImage4/uImage2/" -i "$RES_PATH"/boot.cmd ;;
  aarch64) A=arm64 ;;
esac
[ "$ARCH" != "armhf" ] && mkimage -A "$A" -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 \
            -n "Linux kernel" -d "$ROOTFS_PATH"/boot/vmlinuz-rpi4 "$ROOTFS_PATH"/boot/uImage4

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo ">> Remove kernel modules"

if [ "$DEFAULT_KERNEL_MODULES" != "*" ]; then
  cd "$ROOTFS_PATH"/lib/modules

  # loop all kernel versions
  for d in * ; do
    echo "Removing from $d"

    # copy required modules to tmp dir
    mkdir "$d"_tmp
    cd "$d"
    cp modules.* ../"$d"_tmp
    for m in ${DEFAULT_KERNEL_MODULES} ; do
      echo "finding: $m"
      find ./ -name "$m".ko -print -exec cp --parents {} ../"$d"_tmp \;
    done
    cd ..

    # replace original modules dir with new one
    rm -rf "$d"
    mv "$d"_tmp "$d"
  done

  cd "$WORK_PATH"
else
  echo "skiped -> keep all modules"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create boot FS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Configure boot FS"

# download base firmware
mkdir -p ${BOOTFS_PATH}
echo "   Getting firmware from ${RPI_FIRMWARE_BRANCH} branch"
git clone https://github.com/raspberrypi/firmware --depth 1 \
  --branch ${RPI_FIRMWARE_BRANCH} --filter=blob:none \
  --sparse /tmp/firmware/ && \
  (cd /tmp/firmware/ && \
   git sparse-checkout add boot/ && \
   git checkout)
find /tmp/firmware/boot -maxdepth 1 -type f \( -name "*.dat" -o -name "*.elf" -o -name "*.bin" \) \
   -exec cp {} ${BOOTFS_PATH} \;
rm -rf /tmp/firmware
ls -lah ${BOOTFS_PATH}

# copy linux device trees and overlays to boot
# determine dtb and overlay path
DTB_SOURCE_PATH=""
if find "${ROOTFS_PATH}/boot/dtbs-rpi/" -quit -name "*-rpi-*.dtb" -type f 2>/dev/null; then
  DTB_SOURCE_PATH="${ROOTFS_PATH}/boot/dtbs-rpi"
elif find "${ROOTFS_PATH}/boot/" -quit -name "*-rpi-*.dtb" -type f 2>/dev/null; then
  DTB_SOURCE_PATH="${ROOTFS_PATH}/boot"
else
  echo "Could not determine device trees source path!"
  exit 1
fi
cp -v ${DTB_SOURCE_PATH}/*-rpi-*.dtb ${BOOTFS_PATH}/

OVERLAY_SOURCE_PATH=""
if [ -d "${ROOTFS_PATH}/boot/dtbs-rpi/overlays" ]; then
  OVERLAY_SOURCE_PATH="${ROOTFS_PATH}/boot/dtbs-rpi/overlays"
elif [ -d "${ROOTFS_PATH}/boot/overlays" ]; then
  OVERLAY_SOURCE_PATH="${ROOTFS_PATH}/boot/overlays"
else
  echo "Could not determine overlay source path!"
  exit 1
fi
cp -vr ${OVERLAY_SOURCE_PATH} ${BOOTFS_PATH}/

# copy u-boot
cp /uboot/* ${BOOTFS_PATH}/

# generate boot script
mkimage -A "$A" -T script -C none -n "Boot script" -d ${RES_PATH}/boot.cmd ${BOOTFS_PATH}/boot.scr

M4ARG="-D xARCH=$ARCH"
if [ -f "$INPUT_PATH"/m4/hdmi.m4 ]; then
  M4ARG="$M4ARG -D xHDMI=$INPUT_PATH/m4/hdmi.m4"
fi

echo "generating config.txt"
echo "..."
eval m4 "$M4ARG" "$RES_PATH"/m4/config.txt.m4 > "$BOOTFS_PATH"/config.txt
cat "$BOOTFS_PATH"/config.txt
echo "..."
echo "${CMDLINE}" >${BOOTFS_PATH}/cmdline.txt
echo "cmdline.txt"
cat ${BOOTFS_PATH}/cmdline.txt
echo "..."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Custom modification
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -f ${INPUT_PATH}/${CUSTOM_IMAGE_SCRIPT} ]; then
# shellcheck source=tests/simple-image/image.sh
  . ${INPUT_PATH}/${CUSTOM_IMAGE_SCRIPT}
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Cleanup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# create resolv.conf symlink for running system
ln -fs /data/etc/resolv.conf ${ROOTFS_PATH}/etc/resolv.conf

rm -rf ${ROOTFS_PATH}/var/cache/apk/*
rm -rf ${ROOTFS_PATH}/boot/initramfs*
rm -rf ${ROOTFS_PATH}/boot/System*
rm -rf ${ROOTFS_PATH}/boot/config*
rm -rf ${ROOTFS_PATH}/boot/vmlinuz*
rm -rf ${ROOTFS_PATH}/boot/dtbs-rpi*

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create image
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ">> Create SD card image"

# boot partition
m4 -D xFS=vfat -D xIMAGE=boot.xFS -D xLABEL="BOOT" -D xSIZE="$SIZE_BOOT" \
  "$RES_PATH"/m4/genimage.m4 > "$WORK_PATH"/genimage_boot.cfg
make_image ${BOOTFS_PATH} ${WORK_PATH}/genimage_boot.cfg

# root partition
m4 -D xFS=ext4 -D xIMAGE=rootfs.xFS -D xLABEL="rootfs" -D xSIZE="$SIZE_ROOT_FS" \
  "$RES_PATH"/m4/genimage.m4 > "$WORK_PATH"/genimage_root.cfg
make_image ${ROOTFS_PATH} ${WORK_PATH}/genimage_root.cfg

# data partition
m4 -D xFS=ext4 -D xIMAGE=datafs.xFS -D xLABEL="data" -D xSIZE="$SIZE_DATA" \
  "$RES_PATH"/m4/genimage.m4 > "$WORK_PATH"/genimage_data.cfg
make_image ${DATAFS_PATH} ${WORK_PATH}/genimage_data.cfg

# sd card image
m4 -D xSIZE_ROOT="$SIZE_ROOT_PART" \
  "$RES_PATH"/m4/sdcard.m4 > "$WORK_PATH"/genimage_sdcard.cfg
make_image ${IMAGE_PATH} ${WORK_PATH}/genimage_sdcard.cfg

echo ">> Compress images"
# copy final image
pigz -c ${IMAGE_PATH}/sdcard.img > ${OUTPUT_PATH}/${IMG_NAME}.img.gz
pigz -c ${IMAGE_PATH}/rootfs.ext4 > ${OUTPUT_PATH}/${IMG_NAME}_update.img.gz

# create checksums
cd ${OUTPUT_PATH}/
sha256sum ${IMG_NAME}.img.gz > ${IMG_NAME}.img.gz.sha256
sha256sum ${IMG_NAME}_update.img.gz > ${IMG_NAME}_update.img.gz.sha256

echo
echo ">> Uncompressed Sizes"
echo "size of uboot partition: $SIZE_BOOT	| size of files on uboot partition:	$(du -sh ${BOOTFS_PATH} | sed "s/\s.*//")"
echo "size of root partition:  $SIZE_ROOT_PART"
echo "size of root filesystem: $SIZE_ROOT_FS	| size of files on root filesystem:	$(du -sh ${ROOTFS_PATH} | sed "s/\s.*//")"
echo "size of data partition:  $SIZE_DATA	| size of files on data partition:	$(du -sh ${DATAFS_PATH} | sed "s/\s.*//")"
echo
echo ">> Finished <<"
