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
LAST_PART=$(grep  "$ROOT_DEV" /proc/partitions | tail -1 | awk '{print $4}' | xargs)
LAST_PART_NUM=$(echo "$LAST_PART" | tail -c 2)

growpart /dev/"$ROOT_DEV" "$LAST_PART_NUM" || echo "problem growing partition"
partx -u /dev/"$LAST_PART"

# unmount last partition
umount /dev/"$LAST_PART"
sync

# resize data filesystem then mark done with resize_done file
resize2fs -p /dev/"$LAST_PART" && logger -t "rc.resizedata" "Root partition successfully resized."

# recheck the partition
e2fsck -p -f /dev/"$LAST_PART"

mount -a

touch /data/resize_done

ebegin "Finished preparing persistent data"
