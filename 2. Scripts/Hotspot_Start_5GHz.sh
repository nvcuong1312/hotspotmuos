#!/bin/bash
# ICON: Hotspot_Start

. /opt/muos/script/var/func.sh

WIFI_IFACE="wlan1"
HOTSPOT_SSID="muOS-AP-5GHz"
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

cat <<EOF > /tmp/wpa_supplicant_ap.conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
fast_reauth=1
update_config=1
ap_scan=2
network={
	ssid="$HOTSPOT_SSID"
	mode=2
	key_mgmt=WPA-PSK
    psk="$HOTSPOT_PW"
	frequency=5180
}
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
# Start WPA_SUPPLICANT (wpa_supplicant)
echo "Starting wpa_supplicant..."
setsid nohup wpa_supplicant -B -i "$WIFI_IFACE" -c /tmp/wpa_supplicant_ap.conf >/dev/null 2>&1 &
WPA_SUPPLICANT=$!
echo $WPA_SUPPLICANT > /tmp/wpa_supplicant.pid
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
