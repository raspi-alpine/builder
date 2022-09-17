# build uImage (for old installs)
A=arm

# uImage2 is for armhf and armv7 only
if [ "$ARCH" != "aarch64" ]; then
  colour_echo "rpi2 image"
  mkimage -A "$A" -O linux -T kernel -C none -a 0x00200000 -e 0x00200000 -n "Linux kernel" \
    -d "$ROOTFS_PATH"/boot/vmlinuz-rpi2 "$ROOTFS_PATH"/boot/uImage2
fi

# there is no uImage4 in armhf
case "$ARCH" in
  armhf)
    colour_echo "rpi image"
    mkimage -A "$A" -O linux -T kernel -C none -a 0x00200000 -e 0x00200000 -n "Linux kernel" \
      -d "$ROOTFS_PATH"/boot/vmlinuz-rpi "$ROOTFS_PATH"/boot/uImage
    sed "s/uImage4/uImage2/" -i "$RES_PATH"/boot.cmd
    ;;
  aarch64)
    A=arm64
    ;;
esac
if [ "$ARCH" != "armhf" ]; then
  colour_echo "rpi4 image"
  mkimage -A "$A" -O linux -T kernel -C none -a 0x00200000 -e 0x00200000 \
    -n "Linux kernel" -d "$ROOTFS_PATH"/boot/vmlinuz-rpi4 "$ROOTFS_PATH"/boot/uImage4
fi
