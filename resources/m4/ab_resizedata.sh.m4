#!/bin/sh -e

# resize already done?
if [ -f ifelse(len(xSIMPLEIMAGE), 0,`/data', `/etc')/resize_done ]; then
  return 0
fi

logger -t "rc.resizedata" "Expanding last partition"

# extract root device name
ROOT_DEV=$(basename "$(ab_bootparam root)" | grep -o '.*[^0-9]')
# get last partition
LAST_PART=$(grep "$ROOT_DEV" /proc/partitions | tail -1 | awk '{print $4}' | xargs)
LAST_PART_NUM=$(echo "$LAST_PART" | grep -Eo '[0-9]+$')

ROOT_DEV=$(echo "$ROOT_DEV" | grep -o '.*[^p]')
growpart /dev/"$ROOT_DEV" "$LAST_PART_NUM" || echo "problem growing partition"
partx -u /dev/"$LAST_PART"

# resize data filesystem then mark done with resize_done file
resize2fs -p /dev/"$LAST_PART" && logger -t "rc.resizedata" "Last partition successfully resized."

touch ifelse(len(xSIMPLEIMAGE), 0,`/data', `/etc')/resize_done
