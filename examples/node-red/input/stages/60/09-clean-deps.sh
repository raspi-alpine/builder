#!/bin/sh

chroot_exec apk del .build-deps
chroot_exec rm -rf /tmp/*
