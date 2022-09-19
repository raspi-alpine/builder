#!/bin/sh

# set user name for node red user, and i2c owner
NME="megapi"
# create user to run node-red
chroot_exec adduser -D -g "Mega User" -h /data/"$NME" "$NME" "$NME"

# copy flow to run at start
cp "$INPUT_PATH"/flows.json "$ROOTFS_PATH"/data/"$NME"/
chroot_exec chown "$NME":"$NME" /data/"$NME"/flows.json

# copy script to run at end of startup
install "$INPUT_PATH"/99-zzstartup.start "$ROOTFS_PATH"/etc/local.d/99-zzstartup.start
# change name in startup script
sed "s/NME=.*/NME=\"$NME\"/" -i "$ROOTFS_PATH"/etc/local.d/99-zzstartup.start

# copy user folder as adduser created in ROOTFS_PATH
cp -a "$ROOTFS_PATH"/data/"$NME" "$DATAFS_PATH"/
rm -rf "$ROOTFS_PATH"/data/"$NME"
