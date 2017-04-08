#!/bin/bash

source ./config.sh

get_aps() {
	iwlist wlan0 scan | sed -e 's/Address/KEK Address/g' | sed -e 's/Encryption/KEK Encryption/g' | sed -e 's/ESSID/KEK ESSID/g' | sed -e 's/Frequency/KEK Frequency/g' | sed -e 's/Quality/KEK Quality/g' | grep "KEK" > $BUFFER
}

wipe_db() {
	sqlite3 $DB "DELETE FROM ap; REINDEX ap; VACUUM;"
}

wipe_qu() {
	sqlite3 $QU "DELETE FROM query; REINDEX query; VACUUM;"
}

make_db() {
while read line
do
	if echo $line | grep "Address" &>/dev/null
	then
		ADDR=`echo $line | awk '{ print $6 }'`
	fi
	if echo $line | grep "Frequency" &>/dev/null
	then
		FREQ=`echo $line | cut -d: -f2 | tr "()" " " | awk '{print $1}'`
		CH=`echo $line | cut -d: -f2 | tr "()" " " | awk '{print $4}'`
	fi
	if echo $line | grep "Quality" &>/dev/null
	then
		QUAL=`echo $line | awk '{print $2}' | cut -d= -f2 | cut -d/ -f1`
		SIG=`echo $line | awk '{print $4}' | cut -d= -f2`
	fi
	if echo $line | grep "Encryption" &>/dev/null
	then
		if [ "`echo $line | cut -d: -f2`" == "on" ]
		then
			ENC=1
		else
			ENC=0
		fi
	fi
	if echo $line | grep "ESSID" &>/dev/null
	then
		ESSID=`echo $line | tr "\"" " " | awk '{print $3}'`
		sqlite3 $DB "INSERT INTO ap ( qual, sig, ch, freq, encrypt, bssid, essid ) VALUES ( $QUAL, $SIG, $CH, $FREQ, $ENC, '$ADDR', '$ESSID' );"
	fi
done < $BUFFER
}

connect_to_opn() {
	nmcli device wifi connect $1
}

check_inet() {
	if ping -c 3 8.8.8.8 &>/dev/null
	then
		return 0
	else
		return 1
	fi
}

get_aps_opn_list() {
	sqlite3 $DB "SELECT essid, bssid, qual FROM ap WHERE encrypt = 0 ORDER BY qual DESC;" > $BUFFER
}

check_opn_aps() {
	if [ `sqlite3 $DB "SELECT essid, bssid, qual FROM ap WHERE encrypt = 0 ORDER BY qual DESC;" | wc -l` != "0" ] &>/dev/null
	then
		return 0
	else
		return 1
	fi
}

make_qu() {
while read line
do
	N=`echo $line | cut -d"|" -f1`
	B=`echo $line | cut -d"|" -f2`

	sqlite3 $QU "INSERT INTO query ( essid, bssid ) VALUES ( '$N', '$B' );"

done < $BUFFER
}

clear_buffer() {
	echo /dev/null > $BUFFER
}

wipe_wifi_c(){
	for k in $(nmcli c | grep -v "eth0" | grep -v "connection" | sed '1d' | awk {'print $2'})
	do
		nmcli c delete $k
	done
}

echo "Lib was include."
