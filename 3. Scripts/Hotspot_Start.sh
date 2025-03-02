#!/bin/bash
# ICON: Hotspot_Start

. /opt/muos/script/var/func.sh

if ! ifconfig wlan1 >/dev/null 2>&1; then
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

setsid bash -c '
# Start Hotspot (hostapd)
echo "Starting Hotspot..."
setsid nohup hostapd /etc/hostapd/hostapd.conf >/dev/null 2>&1 &
HOSTAPD_PID=$!
echo $HOSTAPD_PID > /tmp/hostapd.pid
sleep 2

# Start DHCP (udhcpd)
echo "Starting DHCP..."
setsid nohup udhcpd >/dev/null 2>&1 &
UDHCPD_PID=$!
echo $UDHCPD_PID > /tmp/udhcpd.pid

# Start UPnP (miniupnpd)
echo "Starting UPnP..."
setsid nohup miniupnpd >/dev/null 2>&1 &
MINIUPNPD_PID=$!
echo $MINIUPNPD_PID > /tmp/miniupnpd.pid
' &
disown

sleep 3

exit 0
