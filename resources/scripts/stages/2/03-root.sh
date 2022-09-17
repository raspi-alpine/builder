# root password
root_pw=$(mkpasswd -m sha-512 -s "${DEFAULT_ROOT_PASSWORD}")
cp ${ROOTFS_PATH}/etc/shadow ${ROOTFS_PATH}/etc/shadow.alpine-builder
sed -i "/^root/d" ${ROOTFS_PATH}/etc/shadow.alpine-builder
echo "root:${root_pw}:0:0:::::" >>${ROOTFS_PATH}/etc/shadow.alpine-builder
cp ${ROOTFS_PATH}/etc/shadow.alpine-builder ${DATAFS_PATH}/etc/shadow
if [ -z "${SIMPLE_IMAGE}" ]; then
  ln -fs /data/etc/shadow ${ROOTFS_PATH}/etc/shadow
  rmdir ${ROOTFS_PATH}/root
  ln -s /data/root ${ROOTFS_PATH}/root
else
  rm ${ROOTFS_PATH}/etc/shadow.alpine-builder
fi
