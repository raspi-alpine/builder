(
  mkdir -p ${BOOTFS_PATH}
  mkdir -p ${ROOTFS_PATH}
  cd ${ROOTFS_PATH}
  mkdir -p proc sys tmp run dev/pts dev/shm etc/apk var/lock
  [ -z "${SIMPLE_IMAGE}" ] && mkdir -p data uboot ${DATAFS_PATH}/etc ${DATAFS_PATH}/root ${DATAFS_PATH}/etc/network
)
