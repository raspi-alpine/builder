#!/bin/sh

# echo local startup files (stored in /etc/local.d/)
echo "rc_verbose=yes" >>${ROOTFS_PATH}/etc/conf.d/local
# log to kernel printk buffer by default (read with dmesg)
echo "SYSLOGD_OPTS=\"-t -K\"" >${ROOTFS_PATH}/etc/conf.d/syslog
