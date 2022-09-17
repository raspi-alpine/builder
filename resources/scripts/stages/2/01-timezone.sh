# set timezone
if [ -z "${SIMPLE_IMAGE}" ]; then
  echo "${DEFAULT_TIMEZONE}" >${ROOTFS_PATH}/etc/timezone.alpine-builder
  cp ${ROOTFS_PATH}/etc/timezone.alpine-builder ${DATAFS_PATH}/etc/timezone
  ln -fs /usr/share/zoneinfo/${DEFAULT_TIMEZONE} ${DATAFS_PATH}/etc/localtime
else
  chroot_exec setup-timezone -i ${DEFAULT_TIMEZONE}
fi
