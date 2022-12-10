#!/bin/sh

# cache the sequent systems git repos if not downloaded
ab_git -r https://github.com/SequentMicrosystems/megaind-rpi.git
ab_git -r https://github.com/SequentMicrosystems/16inpind-rpi.git

# cache the sequent systems commands after building use -c to run make in chroot
ab_cache -c -p ${ROOTFS_PATH}"/usr/local/bin/megaind" -s make -a "-C /tmp/megaind-rpi install"
ab_cache -c -p ${ROOTFS_PATH}"/usr/local/bin/16inpind" -s make -a "-C /tmp/16inpind-rpi install"

# don't cache the python install use -c to copy to chroot before running
chroot_exec -c "${INPUT_PATH}"/cache-scripts/install-megaind-python.sh
