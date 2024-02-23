#!/bin/ash

create_image() {
  mkimage -A "$A" -O linux -T kernel -C none -a 0x00200000 -e 0x00200000 -n "Linux kernel" -d "$0" "$1"
}

if [ -n "$OLDKERNEL" ]; then
  # build uImage (for old installs)
  A=arm

  case "$ARCH" in
    armhf)
      # armhf there is no uimage4
      sed "s/uImage4/uImage2/" -i "$RES_PATH"/m4/boot.cmd.m4
      ;;
    aarch64)
      A=arm64
      ;;
  esac

  for VMLINUZ in vmlinuz-rpi vmlinuz-rpi2 vmlinuz-rpi4; do
    FULL_KERN="$ROOTFS_PATH/boot/$VMLINUZ"
    if [ -f "$FULL_KERN" ]; then
      create_image "$FULL_KERN" "${FULL_KERN/vmlinuz-rpi/uImage}"
    fi
  done

  colour_echo "rpi $ARCH image"
else
  colour_echo "skipping kernel wrapper as alpine 3.19 changed kernel names"
fi
