#!/bin/sh

mkdir -p /tmp/keepalived

HOST=`hostname`
KEEPHOST=10.1.255.118
SERVICE="Keepalived"

LASTCHECKF="/tmp/keepalived/StatusHistory"
LASTCHECK=`cat $LASTCHECKF`
grep -q MASTER /etc/keepalived/keepalived.conf
ISMASTER=$?

LOGFILE="/tmp/keepalived/Log"

STATUS=$3

function replaceWords {

case $STATE in 

	0) STATEWORD="OK" ;;
	1) STATEWORD="WARNING" ;;
	3) STATEWORD="CRITICAL" ;;

esac

}

function sendNSCA {
	replaceWords
	echo "$STATE $SERVICE - $STATEWORD - $STATUS - $LASTCHECK is transitioning from the $LASTCHECK to the $STATUS state" > /tmp/keepalived/report.txt

#store the new state to the temp file

	echo $LASTSTATE > $LASTCHECKF
	echo $STATUS > /tmp/keepalived/StatusHistory
	exit 0
}

echo "DEBUG - $STATUS" >> $LOGFILE

# FAULT

if [[ "$STATUS" == "FAULT" ]]; then
	echo "FAULT SEND ALERT" >> $LOGFILE
	STATE=1
	sendNSCA
	exit 0
fi

# Now we check that "BACKUP" isn't the IP addresses

# First we get the primary IP of the box and remove this from our list

ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' |  cut -d: -f2 | cut -d ' ' -f1 > /tmp/keepalived/liveIPs

# Now we get the IP addresses that are active

ip a | grep inet | grep -iv 127.0.0.1 | grep -iv inet6 | cut -d ' ' -f6 | cut -d '/' -f1 >> /tmp/keepalived/liveIPs

# CONFIGUREDIPS=`sort /tmp/COMPANY/keepAliveIPs | uniq`

# We now check the config for keepalived 

cat /etc/keepalived/keepalived.conf | awk '/virtual_ipaddress {/,/}/' | grep -iv 'virtual_ipaddress {' | grep -iv '}' | awk '// { print $LASTCHECK }' >> /tmp/keepalived/liveIPs

# This should be the total IP's configured and in the config

# We now need to do a check that it has taken over correctly

COUNT=`sort /tmp/keepalived/liveIPs | uniq -u | wc -l`

# If we return 0 we know that the config and the IP's match

if [[ "$STATUS" == "MASTER" && "$COUNT" == "0" ]]; then
	if [[ "$COUNT" == 0 ]]; then
		echo "We are the MASTER and we have the VIP" >> $LOGFILE
		STATE=0
		sendNSCA
	else
		echo "We are the MASTER but missing VIPS" >> $LOGFILE
		STATE=3
		sendNSCA
	fi
fi

if [[ "$STATUS" == "BACKUP" && "$COUNT" == "0" ]]; then
	STATE=1
	echo "ERROR - WE are the backup and have vips" >> $LOGFILE
	echo "Shutting down interfaces" >> $LOGFILE
	cat /etc/keepalived/keepalived.conf | awk '/virtual_ipaddress {/,/}/' | grep -iv 'virtual_ipaddress {' | grep -iv '}' | awk '/ / { print $LASTCHECK " dev " $5 }' | while read line
do
	echo "Down $line" >> $LOGFILE
	ip addr del $line
done

elif [[ "$STATUS" == "BACKUP" && "$COUNT" -gt "0" ]]; then
	echo "OK - We are the BACKUP with no VIPS" >> $LOGFILE
	STATE=0
	sendNSCA
else 
	echo "We are already the master" >> $LOGFILE
	STATE=0
	sendNSCA
fi

# Only send alert if the status has changed

if [[ "$STATUS" != "$LASTCHECK" ]]; then
STATE=1
sendNSCA
fi
