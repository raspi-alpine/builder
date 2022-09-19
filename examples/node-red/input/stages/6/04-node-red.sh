# cache the node_modules directory
ab_cache -c -p "${ROOTFS_PATH}"/usr/local/lib/node_modules -s "${INPUT_PATH}"/cache-scripts/install-node-red.sh
# the node* symlinks are in a different directory but built with previous step
ab_cache -p "${ROOTFS_PATH}/usr/local/bin/node*"
