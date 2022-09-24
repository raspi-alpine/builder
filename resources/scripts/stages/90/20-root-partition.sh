#!/bin/sh

# root partition and shrink to minimum size if desired
case "$SIZE_ROOT_FS" in
  0)
    colour_echo 'Will shrink rootfs'
    m4 -D xFS=ext4 -D xIMAGE=rootfs.xFS -D xLABEL="rootfs" -D xSIZE="$SIZE_ROOT_PART" -D xFEATURES="extents,dir_index" -D xEXTRAARGS="-m 0" \
      -D xUSEMKE2FS "$RES_PATH"/m4/genimage.m4 >"$WORK_PATH"/genimage_root.cfg
    make_image ${ROOTFS_PATH} ${WORK_PATH}/genimage_root.cfg
    resize2fs -fM ${IMAGE_PATH}/rootfs.ext4
    resize2fs -fM ${IMAGE_PATH}/rootfs.ext4
    colour_echo "Shrunk rootfs to $(du -h ${IMAGE_PATH}/rootfs.ext4 | cut -f1)"
    ;;
  *)
    colour_echo 'Will not shrink rootfs'
    m4 -D xFS=ext4 -D xIMAGE=rootfs.xFS -D xLABEL="rootfs" -D xSIZE="$SIZE_ROOT_FS" -D xUSEMKE2FS \
      "$RES_PATH"/m4/genimage.m4 >"$WORK_PATH"/genimage_root.cfg
    make_image ${ROOTFS_PATH} ${WORK_PATH}/genimage_root.cfg
    ;;
esac
