# copy linux device trees and overlays to boot
# determine dtb and overlay path
DTB_SOURCE_PATH=""
if find "${ROOTFS_PATH}/boot/dtbs-rpi/" -quit -name "*-rpi-*.dtb" -type f 2>/dev/null; then
  DTB_SOURCE_PATH="${ROOTFS_PATH}/boot/dtbs-rpi"
elif find "${ROOTFS_PATH}/boot/" -quit -name "*-rpi-*.dtb" -type f 2>/dev/null; then
  DTB_SOURCE_PATH="${ROOTFS_PATH}/boot"
else
  echo "Could not determine device trees source path!"
  exit 1
fi
cp ${DTB_SOURCE_PATH}/*-rpi-*.dtb ${BOOTFS_PATH}/

OVERLAY_SOURCE_PATH=""
if [ -d "${ROOTFS_PATH}/boot/dtbs-rpi/overlays" ]; then
  OVERLAY_SOURCE_PATH="${ROOTFS_PATH}/boot/dtbs-rpi/overlays"
elif [ -d "${ROOTFS_PATH}/boot/overlays" ]; then
  OVERLAY_SOURCE_PATH="${ROOTFS_PATH}/boot/overlays"
else
  echo "Could not determine overlay source path!"
  exit 1
fi
cp -r ${OVERLAY_SOURCE_PATH} ${BOOTFS_PATH}/
colour_echo "contents of uboot" "$Cyan"
ls -C ${BOOTFS_PATH}
colour_echo "overlays" "$Cyan"
ls -C "$BOOTFS_PATH"/overlays
colour_echo "end of overlays" "$Cyan"
