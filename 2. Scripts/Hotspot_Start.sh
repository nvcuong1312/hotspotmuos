#!/bin/bash
# ICON: Hotspot_Start

. /opt/muos/script/var/func.sh

WIFI_IFACE="wlan1"
HOTSPOT_SSID="muOS-AP"
HOTSPOT_PW="11223344"
HOTSPOT_IP="192.168.89"

if ! ifconfig $WIFI_IFACE >/dev/null 2>&1; then
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

ip addr flush dev $WIFI_IFACE
ip addr add $HOTSPOT_IP.1/24 dev $WIFI_IFACE

cat <<EOF > /tmp/hostapd.conf
interface=$WIFI_IFACE
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTSPOT_PW
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

cat <<EOF > /tmp/udhcpd.conf
start $HOTSPOT_IP.2
end $HOTSPOT_IP.100
opt subnet 255.255.255.0
opt router $HOTSPOT_IP.1
opt dns 8.8.8.8 8.8.4.4
lease 86400
interface $WIFI_IFACE
EOF

cat <<EOF > /tmp/miniupnpd.conf
ext_ifname=$WIFI_IFACE
listening_ip=$WIFI_IFACE
enable_upnp=yes
secure_mode=no
presentation_url=http://$HOTSPOT_IP.1/
EOF

export WIFI_IFACE HOTSPOT_IP HOTSPOT_SSID

setsid bash -c '
# Start Hostapd (hostapd)
echo "Starting Hostapd..."
setsid nohup hostapd /tmp/hostapd.conf >/dev/null 2>&1 &
HOSTAPD_PID=$!
echo $HOSTAPD_PID > /tmp/hostapd.pid
sleep 2

# Start DHCP (udhcpd)
echo "Starting DHCP..."
setsid nohup udhcpd /tmp/udhcpd.conf >/dev/null 2>&1 &
UDHCPD_PID=$!
echo $UDHCPD_PID > /tmp/udhcpd.pid

# Start UPnP (miniupnpd)
echo "Starting UPnP..."
setsid nohup miniupnpd -f /tmp/miniupnpd.conf >/dev/null 2>&1 &
MINIUPNPD_PID=$!
echo $MINIUPNPD_PID > /tmp/miniupnpd.pid
' &
disown

sleep 3

exit 0
