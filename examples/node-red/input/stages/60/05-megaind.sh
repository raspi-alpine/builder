#!/bin/sh

# cache the git repo with megaind-rpi source if not downloaded
ab_cache -p "${ROOTFS_PATH}"/tmp/megaind-rpi -s git -a "clone --depth 1 https://github.com/SequentMicrosystems/megaind-rpi.git ${ROOTFS_PATH}/tmp/megaind-rpi"

# don't cache the python install use -c to copy to chroot before running
chroot_exec -c "${INPUT_PATH}"/cache-scripts/install-megaind-python.sh

# cache the megaind command after building
ab_cache -c -p "${ROOTFS_PATH}"/usr/local/bin/megaind -s "${INPUT_PATH}"/cache-scripts/install-megaind.sh
