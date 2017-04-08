#!/bin/bash

source ./lib.sh

wipe_db
wipe_qu
clear_buffer

echo "Starting scan APs . . ."
echo 0 > /sys/class/leds/red_led/brightness

while [ $SCANAPS == "1" ]
do
	if check_inet
	then
		echo "Internet enable, wait against..."
		echo 1 > /sys/class/leds/red_led/brightness
		sleep 10
		continue
	fi

	echo 0 > /sys/class/leds/red_led/brightness

	echo "Wipe Wi-Fi connections . . ."
	wipe_wifi_c

	echo "Scan APs . . ."

	wipe_db
	get_aps
	make_db

	echo "Check OPN APs . . ."

	if ! check_opn_aps
	then
		echo "NOT FOUND"
		echo "Waiting . . ."
		sleep 15
		echo ". . . repeat"
		continue
	fi
	echo "FOUND."

	echo "Creating query . . ."

	get_aps_opn_list
	make_qu

	echo "Trying connect to:"
	for i in $(sqlite3 $QU "SELECT bssid FROM query ORDER BY num ASC;")
	do
		echo $i
		connect_to_opn $i
		sleep 5

		if check_inet
		then
			echo "Internet enable."
			break
		else
			echo "No internet, try other aps..."
			sqlite3 $QU "DELETE FROM query WHERE bssid = '$i'" #&>/dev/null
		fi
	done

	echo "REPEAT..."
	clear_buffer
	sleep 1
done
