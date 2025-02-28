#!/bin/sh

. /opt/muos/script/var/func.sh

if ifconfig wlan1 >/dev/null 2>&1; then
else
    if ! lsmod | grep -wq "$(GET_VAR "device" "network/name")"; then
	rmmod "$(GET_VAR "device" "network/module")"
	sleep 1
	modprobe --force-modversion "$(GET_VAR "device" "network/module")"
	while [ ! -d "/sys/class/net/$(GET_VAR "device" "network/iface")" ]; do
		sleep 1
	done
	fi

	rfkill unblock all
	ip link set "$(GET_VAR "device" "network/iface")" up
	iw dev "$(GET_VAR "device" "network/iface")" set power_save off
fi

if [ ! -e /var/lib/misc/udhcpd.leases ]; then
    touch /var/lib/misc/udhcpd.leases
	chmod 644 /var/lib/misc/udhcpd.leases
fi

ip addr flush dev wlan1
ip addr add 192.168.89.1/24 dev wlan1

echo "Starting Hotspot..."
nohup hostapd /etc/hostapd/hostapd.conf &
sleep 3

nohup udhcpd &
sleep 3

nohup miniupnpd &
sleep 3
