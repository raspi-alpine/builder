#!/bin/sh

# device manager service for device creation and /dev/stderr etc
case ${DEV} in
  eudev)
    chroot_exec setup-udev -n
    install ${RES_PATH}/scripts/ab_root.sh ${ROOTFS_PATH}/etc/init.d/ab_root
    DEFAULT_SERVICES="${DEFAULT_SERVICES} ab_root"
    if [ "$DEFAULT_KERNEL_MODULES" != "*" ]; then
      DEFAULT_KERNEL_MODULES="$DEFAULT_KERNEL_MODULES uio bcm2835-mmal-vchiq brcmutil cfg80211 videobuf2-vmalloc videobuf2-dma-contig v4l2-mem2mem"
    fi
    ;;
  *)
    SYSINIT_SERVICES="${SYSINIT_SERVICES} mdev"
    ;;
esac
