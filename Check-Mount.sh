#!/bin/sh
# echo "Remount Initiated $(date)"
appname=$(basename $0)

# Change this to the location of your Amazon Cloud Mountpoint
acdmount="/home/plex/.acd-sorted/"

if [ $(ls -l $acdmount  | grep -v '^total' | wc -l) -gt 0 ]; then
    echo "Everything Looks ok $(date)" >> /home/plex/scripts/logs/Check-Mount.log
    exit
fi

if [ $(ps -Al | grep $appname | wc -l) -gt 2 ]; then
        echo "Already Running! Count $(ps -Al | grep $appname | wc -l)"
        exit
fi
echo "Remounting $(date)" >> /home/plex/scripts/logs/Check-Mount.log

umount -f "$acdmount"
syncresult=$(/usr/local/bin/acdcli sync 2>&1)
if [ $(echo $syncresult | grep -i error | wc -l) -gt 0 ]; then
        echo Error with the DB
        rm ~/.cache/acd_cli/nodes.db
        /usr/local/bin/acdcli sync
        sleep 10
fi
echo $syncresult
mount "$acdmount"

echo "Remount Done $(date)" >> /home/plex/scripts/logs/Check-Mount.log
