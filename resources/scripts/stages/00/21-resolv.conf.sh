#!/bin/sh

# Copy host's resolv config for building
cp -L /etc/resolv.conf ${ROOTFS_PATH}/etc/resolv.conf
