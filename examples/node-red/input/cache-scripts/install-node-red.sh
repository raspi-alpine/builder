#!/bin/sh

# npm writes to root during install
mv /root /root.orig
npm config set foreground-scripts=true
npm install -g node-red @flowfuse/node-red-dashboard \
  @flowfuse/node-red-dashboard-2-ui-led node-red-contrib-chronos node-red-contrib-moment node-red-contrib-modbus

# sequent microstsyems node red
npm install -g node-red-contrib-sm-ind node-red-contrib-sm-16inputs

rm -rf /root
mv /root.orig /root
