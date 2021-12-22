#!/sbin/openrc-run
# shellcheck shell=ash
# shellcheck disable=SC2034

command="/usr/bin/test_app"
pidfile="/var/run/test_app.pid"
command_args=""
command_background=true


depend() {
	use logger dns
	need net
	after firewall
}
