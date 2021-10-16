#!/bin/sh

#check net and apk working
apk add --no-cache python3

install ${INPUT_PATH}/hello.sh ${ROOTFS_PATH}/etc/local.d/hello.start
