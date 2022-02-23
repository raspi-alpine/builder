#!/sbin/openrc-run
# shellcheck shell=ash

# shellcheck disable=SC2034
description="Sets the /dev/root symlink"

depend()
{
	need dev
	keyword -docker -lxc -openvz -prefix -systemd-nspawn -uml -vserver -xenu
}

start()
{
	ebegin "Setting /dev/root symlink"
	ROOTDEV="$(sed -e "s/.*root=//" -e "s/\s.*//" /proc/cmdline)"
	ln -fs "$ROOTDEV" /dev/root
	eend 0
}
