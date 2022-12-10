# Example with node-red and building python and other deps

The arch for the image is set to aarch64 in `megaind.env`

This example installs the software to use the [SequentSystems megaind-rpi board](https://github.com/SequentMicrosystems/megaind-rpi), it also installs the node-red module for 16inputs-rpi.
To use the RS485 on the card which can be passed through to the PI uart pins (14,15) the `silent` `UBOOT_PACKAGE` is used and `CMDLINE`
is changed to remove the console on serial0

The `flows.json` file is started by node-red on startup, it is in the read/write data partition.  But once node-red has created its files it can be in a read only filesystem, which means it can no longer be edited.

The example flow expects the board at id 7, this can be changed in the ui.

The WIFI password section of `image.sh` is commented out at the bottom and needs uncommenting and editing with the correct SSID and password/PSK.

Bluetooth is disabled to activate the hardware serial port, a login is started on the serial console as well.

AVAHI is started with the DEFAULT_HOSTNAME set in `megaind.env` so it can be accessed with that name instead of an ip address.

The default password for root is set in `megaind.env` which should be changed.
