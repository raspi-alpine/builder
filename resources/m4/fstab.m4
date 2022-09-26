/dev/root       /           ext4    defaults,ro         0 1
LABEL=BOOT      ifelse(len(xSIMPLEIMAGE), 0,`/uboot', `/boot')      vfat    defaults,ro         0 2
ifelse(len(xSIMPLEIMAGE), 0,`LABEL=data      /data       ext4    defaults            0 2')

proc            /proc       proc   defaults             0 0
sysfs           /sys        sysfs  defaults             0 0
devpts          /dev/pts    devpts gid=4,mode=620       0 0
tmpfs           /dev/shm    tmpfs  defaults             0 0
tmpfs           /tmp        tmpfs  defaults             0 0
tmpfs           /run        tmpfs  defaults             0 0
tmpfs           /var/lock   tmpfs  defaults             0 0
