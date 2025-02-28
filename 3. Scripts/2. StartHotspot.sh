#!/bin/sh

. /opt/muos/script/var/func.sh

if [ ! -e /var/lib/misc/udhcpd.leases ]; then
    touch /var/lib/misc/udhcpd.leases
	chmod 644 /var/lib/misc/udhcpd.leases
fi

ip addr flush dev wlan1
ip addr add 192.168.89.1/24 dev wlan1

echo "1. Starting Hotspot..."
nohup hostapd /etc/hostapd/hostapd.conf &
sleep 3

echo "2. Starting DHCP..."
nohup udhcpd &
sleep 3

echo "3. Starting UPnP..."
nohup miniupnpd &
sleep 3
