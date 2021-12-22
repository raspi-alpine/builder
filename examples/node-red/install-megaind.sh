#!/bin/sh

# install megaind python library
cd /tmp/megaind-rpi/python || exit 1
python3 setup.py install

# yarn writes to root folder during install
mv /root /root.old
mkdir /root

# npm gives the error npm ERR! Exit handler never called!
# node red, dashboard, and some other useful packages
yarn global add node-gyp
yarn global add node-red node-red-dashboard node-red-contrib-ui-led node-red-contrib-chronos node-red-contrib-moment 
# node-red-contrib-modbus not compatible with node 16 until v6

# sequent microstsyems node red 
yarn global add node-red-contrib-sm-ind node-red-contrib-sm-16inputs

rm -rf /root
mv /root.old /root

