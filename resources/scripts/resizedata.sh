#!/bin/sh -e

# resize already done?
if [ -f /data/resize_done ]; then
  return 0
fi

logger -t "rc.resizedata" "Expanding data partition"

# extract root device name
ROOT_DEV=$(basename "$(ab_bootparam root)" | grep -o '.*[^0-9]')

# get last partition
LAST_PART=$(grep "$ROOT_DEV" /proc/partitions | tail -1 | awk '{print $4}' | xargs)
LAST_PART_NUM=$(echo "$LAST_PART" | grep -Eo '[0-9]+$')

# unmount and check last partition
umount /dev/"$LAST_PART"
e2fsck -p -f /dev/"$LAST_PART"
mount /dev/"$LAST_PART"

ROOT_DEV=$(echo "$ROOT_DEV" | grep -o '.*[^p]')
growpart /dev/"$ROOT_DEV" "$LAST_PART_NUM" || echo "problem growing partition"
partx -u /dev/"$LAST_PART"

# unmount last partition
umount /dev/"$LAST_PART"
e2fsck -p -f /dev/"$LAST_PART"

# resize data filesystem then mark done with resize_done file
resize2fs -p /dev/"$LAST_PART" && logger -t "rc.resizedata" "Root partition successfully resized."

# recheck the partition
e2fsck -p -f /dev/"$LAST_PART"

mount -a

touch /data/resize_done

ebegin "Finished preparing persistent data"
