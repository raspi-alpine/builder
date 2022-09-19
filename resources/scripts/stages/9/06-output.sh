#!/bin/sh

echo
colour_echo ">> Uncompressed Sizes"
colour_echo "size of uboot partition: $SIZE_BOOT	| size of files on uboot partition:     $(du -sh ${BOOTFS_PATH} | sed "s/\s.*//")" "$Yellow"
colour_echo "size of root partition:  $SIZE_ROOT_PART" "$Yellow"
colour_echo "size of root filesystem: $SIZE_ROOT_FS	| size of files on root filesystem:     $(du -sh ${ROOTFS_PATH} | sed "s/\s.*//")" "$Yellow"
colour_echo "size of data partition:  $SIZE_DATA	| size of files on data partition:      $(du -sh ${DATAFS_PATH} | sed "s/\s.*//")" "$Yellow"
echo
