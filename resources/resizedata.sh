#!/bin/sh -e

# resize already done?
if [ -f /data/resize_done ]; then
  return 0
fi

logger -t "rc.resizedata" "Expanding root partition"

# detect root partition device
ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
if [ -z "$ROOT_PART" ] ; then
  log_warning_msg "unable to detect root partition device"
  return 1
fi

# extract root device name
case "$ROOT_PART" in
  mmcblk0*) ROOT_DEV=mmcblk0 ;;
  sda*)     ROOT_DEV=sda ;;
esac

# get last partition
LAST_PART_NUM=$(parted /dev/"$ROOT_DEV" -ms unit s p | tail -n 1 | cut -f 1 -d:)
LAST_PART="${ROOT_DEV}p${LAST_PART_NUM}"

# unmount last partition
umount /dev/"$LAST_PART"

# check the partition
e2fsck -p -f /dev/"$LAST_PART"

growpart /dev/"$ROOT_DEV" "$LAST_PART_NUM"

# resize data filesystem then mark done with resize_done file
resize2fs -p /dev/"$LAST_PART" && logger -t "rc.resizedata" "Root partition successfully resized."

# recheck the partition
e2fsck -p -f /dev/"$LAST_PART"

mount -a

touch /data/resize_done
