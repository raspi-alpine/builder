#!/bin/sh

colour_echo ">> Compress images"
# copy final image
mkdir -p ${OUTPUT_PATH}
pigz -c ${IMAGE_PATH}/sdcard.img >${OUTPUT_PATH}/${IMG_NAME}.img.gz
pigz -c ${IMAGE_PATH}/rootfs.ext4 >${OUTPUT_PATH}/${IMG_NAME}_update.img.gz

# create checksums
cd ${OUTPUT_PATH}/ || exit 1
sha256sum ${IMG_NAME}.img.gz >${IMG_NAME}.img.gz.sha256
sha256sum ${IMG_NAME}_update.img.gz >${IMG_NAME}_update.img.gz.sha256
