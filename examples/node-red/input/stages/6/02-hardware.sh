# enable i2c
echo 'i2c-dev' >"$ROOTFS_PATH"/etc/modules-load.d/i2c.conf
echo 'dtparam=i2c_arm=on' >>"$BOOTFS_PATH"/config.txt

# enable hardware serial console
echo 'dtoverlay=miniuart-bt' >>"$BOOTFS_PATH"/config.txt
sed -e "s/#ttyS0/ttyAMA0/" -e "s/ttyS0/ttyAMA0/" -i "$ROOTFS_PATH"/etc/inittab
