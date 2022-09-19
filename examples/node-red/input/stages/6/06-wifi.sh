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
