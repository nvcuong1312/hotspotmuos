#!/bin/sh

. /opt/muos/script/var/func.sh

touch /var/lib/misc/udhcpd.leases
chmod 644 /var/lib/misc/udhcpd.leases

ip addr add 192.168.89.1/24 dev wlan1

sleep 3
echo "2. Starting DHCP..."
udhcpd &
sleep 3

echo "3. Starting UPnP..."
miniupnpd &
sleep 3