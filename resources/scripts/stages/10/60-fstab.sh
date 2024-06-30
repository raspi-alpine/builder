#!/bin/sh

M4ARG="-D xSIMPLEIMAGE=${SIMPLE_IMAGE}"
if [ -f "${INPUT_PATH}/m4/fstab.m4" ]; then
  colour_echo "   adding user fstab"
  M4ARG="$M4ARG -D xFSTAB=${INPUT_PATH}/m4/fstab.m4"
fi
if [ -n "$LIB_LOG" ]; then
  M4ARG="$M4ARG -D xLIBLOG=${LIB_LOG}"
fi
if [ -n "$OVERLAY" ]; then
  M4ARG="$M4ARG -D xOVERLAY=${OVERLAY}"
  echo 'overlay' >"$ROOTFS_PATH"/etc/modules-load.d/overlay.conf
fi
if [ "$DEFAULT_DROPBEAR_ENABLED" = "true" ]; then
  M4ARG="$M4ARG -D xDROPBEAR=TRUE"
fi
colour_echo "   calling m4 with $M4ARG"
# install fstab
m4 ${M4ARG} "$RES_PATH"/m4/fstab.m4 >${ROOTFS_PATH}/etc/fstab

cat ${ROOTFS_PATH}/etc/fstab
