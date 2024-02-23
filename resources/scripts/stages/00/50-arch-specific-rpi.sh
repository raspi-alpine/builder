#!/bin/sh

if [ -n "$OLDKERNEL" ]; then
  case "$ARCH" in
    armhf)
      chroot_exec apk add linux-rpi linux-rpi2
      ;;
    armv7)
      chroot_exec apk add linux-rpi2 linux-rpi4
      ;;
    aarch64)
      chroot_exec apk add linux-rpi4
      ;;
  esac
else
  chroot_exec apk add linux-rpi
fi

case "$RPI_FIRMWARE_BRANCH" in
  alpine)
    chroot_exec apk add raspberrypi-bootloader raspberrypi-bootloader-cutdown
    ;;
esac
