#!/bin/sh

. /opt/muos/script/var/func.sh

ip addr flush dev wlan1

kill $(ps aux | grep hostapd | grep -v grep | awk '{print $1}')
kill $(ps aux | grep udhcpd | grep -v grep | awk '{print $1}')
kill $(ps aux | grep miniupnpd | grep -v grep | awk '{print $1}')


sleep 1