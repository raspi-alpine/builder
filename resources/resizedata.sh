#!/bin/sh -e

# resize already done?
if [ -f /data/resize_done ]; then
  return 0
fi

logger -t "rc.resizedata" "Expanding root partition"

# Detect root partition device
ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
if [ -z "$ROOT_PART" ] ; then
  log_warning_msg "unable to detect root partition device"
  return 1
fi

# Extract root device name
case "${ROOT_PART}" in
  mmcblk0*) ROOT_DEV=mmcblk0 ;;
  sda*)     ROOT_DEV=sda ;;
esac

# get last partition
LAST_PART_NUM=$(parted /dev/${ROOT_DEV} -ms unit s p | tail -n 1 | cut -f 1 -d:)
LAST_PART="${ROOT_DEV}p${LAST_PART_NUM}"

# unmount last partition
umount /dev/${LAST_PART}

# Get the starting offset of last partition
PART_START=$(parted /dev/${ROOT_DEV} -ms unit s p | grep "^${LAST_PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
if [ -z "$PART_START" ] ; then
  logger -t "rc.resizedata" "${ROOT_DEV} unable to get starting sector of the partition"
  return 1
fi

# Get the possible last sector for the root partition
PART_LAST=$(fdisk -l /dev/${ROOT_DEV} | grep '^Disk.*sectors' | awk '{ print $7 - 1 }')
if [ -z "$PART_LAST" ] ; then
  logger -t "rc.resizedata" "${ROOT_DEV} unable to get last sector of the partition"
  return 1
fi

### Since rc.local is run with "sh -e", let's add "|| true" to prevent premature exit
echo "resize partition"
fdisk /dev/${ROOT_DEV} > /dev/null <<EOF2 || true
p
d
$LAST_PART_NUM
n
p
$LAST_PART_NUM
$PART_START
$PART_LAST
p
w
EOF2

# Reload the partition table, resize root filesystem then remove resizing code from this file
partprobe /dev/${ROOT_DEV} &&
  resize2fs -p /dev/${LAST_PART} &&
  logger -t "rc.resizedata" "Root partition successfully resized."

mount -a

touch /data/resize_done
