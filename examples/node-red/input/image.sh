#!/bin/sh

# set user name for node red user, and i2c owner
NME="megapi"

# copy script to run at end of startup
install "$INPUT_PATH"/99-zzstartup.start "$ROOTFS_PATH"/etc/local.d/99-zzstartup.start
# change name in startup script
sed "s/NME=.*/NME=\"$NME\"/" -i "$ROOTFS_PATH"/etc/local.d/99-zzstartup.start

# enable i2c
echo 'i2c-dev' >"$ROOTFS_PATH"/etc/modules-load.d/i2c.conf
echo 'dtparam=i2c_arm=on' >>"$BOOTFS_PATH"/config.txt

# enable hardware serial console
echo 'dtoverlay=miniuart-bt' >>"$BOOTFS_PATH"/config.txt
sed -e "s/#ttyS0/ttyAMA0/" -e "s/ttyS0/ttyAMA0/" -i "$ROOTFS_PATH"/etc/inittab

# install deps and add avahi to default runlevel
chroot_exec apk add avahi dbus dropbear-scp htop npm python3 py3-smbus
chroot_exec rc-update add avahi-daemon default
# set avahi name to DEFAULT_HOSTNAME value
sed "s/#host-name.*/host-name=${DEFAULT_HOSTNAME}/" -i "$ROOTFS_PATH"/etc/avahi/avahi-daemon.conf

# add deps needed for building
chroot_exec apk add --virtual .build-deps build-base linux-headers python3-dev py3-setuptools

# cache the git repo with megaind-rpi source if not downloaded
ab_cache -p ${ROOTFS_PATH}/tmp/megaind-rpi -s git -a "clone --depth 1 https://github.com/SequentMicrosystems/megaind-rpi.git ${ROOTFS_PATH}/tmp/megaind-rpi"

# don't cache the python install use -c to copy to chroot before running
chroot_exec -c ${INPUT_PATH}/cache-scripts/install-megaind-python.sh

# cache the node_modules directory
ab_cache -c -p ${ROOTFS_PATH}/usr/local/lib/node_modules -s ${INPUT_PATH}/cache-scripts/install-node-red.sh
# the node* symlinks are in a different directory but built with previous step
ab_cache -p "${ROOTFS_PATH}/usr/local/bin/node*"

# cache the megaind command after building
ab_cache -c -p "${ROOTFS_PATH}/usr/local/bin/megaind" -s ${INPUT_PATH}/cache-scripts/install-megaind.sh

# create user to run node-red
chroot_exec adduser -D -g "Mega User" -h /data/"$NME" "$NME" "$NME"

chroot_exec apk del .build-deps
chroot_exec rm -rf /tmp/*

# copy flow to run at start
cp "$INPUT_PATH"/flows.json "$ROOTFS_PATH"/data/"$NME"/
chroot_exec chown "$NME":"$NME" /data/"$NME"/flows.json
# copy user folder as adduser created in ROOTFS_PATH
cp -a "$ROOTFS_PATH"/data/"$NME" "$DATAFS_PATH"/
rm -rf "$ROOTFS_PATH"/data/"$NME"
ls -lah "$ROOTFS_PATH"

# wifi stuff
chroot_exec apk add wireless-tools wpa_supplicant
chroot_exec rc-update add wpa_supplicant default
echo "brcmfmac" >>"$ROOTFS_PATH"/etc/modules

cat >>"$ROOTFS_PATH"/etc/network/interfaces.alpine-builder <<EOF

auto wlan0
iface wlan0 inet dhcp
EOF

cp "$ROOTFS_PATH"/etc/network/interfaces.alpine-builder "$DATAFS_PATH"/etc/network/interfaces

# ** CHANGE MYSSID and MYPSK **
#chroot_exec sh -c "wpa_passphrase MYSSID MYPSK > /etc/wpa_supplicant/wpa_supplicant.conf"
# can be used more than once to add more networks
#chroot_exec sh -c "wpa_passphrase MYSSID2 MYPSK2 >> /etc/wpa_supplicant/wpa_supplicant.conf"
# ** CHANGE MYSSID and MYPSK **
