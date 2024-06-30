#!/bin/sh

# generate boot script
case ${ARCH} in
  aarch64)
    A=arm64
    ;;
  *)
    A=arm
    ;;
esac

m4 -D xOLDKERNEL="$OLDKERNEL" "$RES_PATH"/m4/boot.cmd.m4 >"$WORK_PATH"/boot.cmd
mkimage -A "$A" -T script -C none -n "Boot script" -d ${WORK_PATH}/boot.cmd ${BOOTFS_PATH}/boot.scr

M4ARG="-D xARCH=$ARCH -D xPI3USB=$PI3USB"
if [ -f "$INPUT_PATH"/m4/hdmi.m4 ]; then
  M4ARG="$M4ARG -D xHDMI=$INPUT_PATH/m4/hdmi.m4"
fi
