#!/sbin/openrc-run
# shellcheck shell=ash

depend() {
  need localmount
  before logger
  after clock root sysctl
  keyword -prefix -timeout
}

start() {
  ebegin Saving boot log
  [ -e /var/log/bootlog ] && mv /var/log/bootlog /var/log/bootlog.old
  dmesg >/var/log/bootlog
  eend 0
}
