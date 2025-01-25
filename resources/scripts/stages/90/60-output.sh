#!/bin/sh

echo
colour_echo ">> Uncompressed Sizes"
colour_echo "size of uboot partition: $SIZE_BOOT	| size of files on uboot partition:     $(du -sh ${BOOTFS_PATH} | sed "s/\s.*//")" -Yellow
colour_echo "size of root partition:  $SIZE_ROOT_PART" -Yellow
colour_echo "size of root filesystem: $SIZE_ROOT_FS	| size of files on root filesystem:     $(du -sh ${ROOTFS_PATH} | sed "s/\s.*//")" -Yellow
colour_echo "size of data partition:  $SIZE_DATA	| size of files on data partition:      $(du -sh ${DATAFS_PATH} | sed "s/\s.*//")" -Yellow
echo
if [ -z "$OLDKERNEL" ]; then
  colour_echo "Alpine branch $ALPINE_BRANCH used, to update from Alpine 3.18 or older use the full image" -Red
  colour_echo "As the kernel names and u-boot script have changed" -Red
  echo
fi
