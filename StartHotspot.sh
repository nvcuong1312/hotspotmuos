#!/bin/sh

. /opt/muos/script/var/func.sh

hostapd /etc/hostapd/hostapd.conf &

sleep 2
echo "ahihi"
sleep 2
exit