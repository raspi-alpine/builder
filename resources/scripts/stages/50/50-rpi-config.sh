#!/bin/sh

colour_echo "generating config.txt" "$Cyan"
colour_echo "..." "$Cyan"
eval m4 "$M4ARG" ${RES_PATH}/m4/config.txt.m4 >${BOOTFS_PATH}/config.txt
cat ${BOOTFS_PATH}/config.txt
colour_echo "..." "$Cyan"
echo "${CMDLINE}" >${BOOTFS_PATH}/cmdline.txt
colour_echo "cmdline.txt" "$Cyan"
cat ${BOOTFS_PATH}/cmdline.txt
colour_echo "..." "$Cyan"
