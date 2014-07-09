#!/bin/bash

# Read the local log
# Format of the log file: 
# 0 keepalive_011 - CRITICAL - Replication delay 10 seconds"

PROCCOUNT=`ps aux | grep [k]eepalived | grep -iv keepalived.sh`
if [[ "$PROCCOUNT" > 1 ]]; then
        cat /tmp/keepalived/report.txt
else
        echo "2 Keepalived - $HOSTNAME - Keepalived not running"
fi
