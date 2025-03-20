#!/bin/sh
# ICON: Hotspot_Stop

. /opt/muos/script/var/func.sh

echo "Stopping Hotspot..."

ip addr flush dev wlan1

hostapdId=$(ps aux | grep hostapd | grep "/tmp/hostapd.conf" | grep -v grep | awk '{print $1}')
if [ -n "$hostapdId" ]; then
	kill "$hostapdId"
fi

wpaSupId=$(ps aux | grep wpa_supplicant | grep "/tmp/wpa_supplicant_ap.conf" | grep -v grep | awk '{print $1}')
if [ -n "$wpaSupId" ]; then
	kill "$wpaSupId"
fi

udhcpdId=$(ps aux | grep udhcpd | grep -v grep | awk '{print $1}')
if [ -n "$udhcpdId" ]; then
	kill "$udhcpdId"
fi

miniupnpdId=$(ps aux | grep miniupnpd | grep -v grep | awk '{print $1}')
if [ -n "$miniupnpdId" ]; then
	kill "$miniupnpdId"
fi

sleep 1