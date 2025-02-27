#!/bin/sh

. /opt/muos/script/var/func.sh

kill $(ps aux | grep hostapd | grep -v grep | awk '{print $1}')

sleep 3