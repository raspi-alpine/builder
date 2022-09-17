case ${RPI_FIRMWARE_BRANCH} in
  alpine)
    FPATH="${ROOTFS_PATH}/boot"
    ;;
  *)
    ab_cache -p /tmp/firmware -s ${RES_PATH}scripts/cache-scripts/download_firmware.sh -a "-r ${RPI_FIRMWARE_GIT} -b ${RPI_FIRMWARE_BRANCH}"
    FPATH="/tmp/firmware/boot"
    ;;
esac

find "$FPATH" -maxdepth 1 -type f \( -name "*.dat" -o -name "*.elf" -o -name "*.bin" \) \
  -exec cp {} ${BOOTFS_PATH} \;
