/dev/root            /              ext4     defaults,ro         0 1
LABEL=BOOT           ifelse(len(xSIMPLEIMAGE), 0,`/uboot', `/boot ')         vfat     defaults,ro         0 2
ifelse(len(xSIMPLEIMAGE), 0,`LABEL=data           /data          ext4     defaults            0 2')
/data/root           /root          none     defaults,bind       0 0
ifdef(`xLIBLOG', `/data/var/lib        /var/lib       none     defaults,bind       0 0
/data/var/log        /var/log       none     defaults\,bind       0 0')
ifdef(`xOVERLAY', `overlay              /etc           overlay  defaults,nofail,lowerdir=/etc,upperdir=/data/etc,workdir=/data/workdir 0 0',
`ifdef(`xDROPBEAR', `/data/etc/dropbear   /etc/dropbear  none     defaults,bind       0 0')')

proc                 /proc          proc     defaults            0 0
sysfs                /sys           sysfs    defaults            0 0
devpts               /dev/pts       devpts   gid=4,mode=620      0 0
tmpfs                /dev/shm       tmpfs    defaults            0 0
tmpfs                /tmp           tmpfs    defaults            0 0
tmpfs                /run           tmpfs    defaults            0 0
tmpfs                /var/lock      tmpfs    defaults            0 0

ifdef(`xFSTAB', `include(xFSTAB)')
