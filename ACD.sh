#!/bin/bash

if [ -z "$1" ]; then
        echo "The script must tbe run with the following syntax: ./ACDControl.sh Start|Stop|Restart|Sync"
        echo "This script provides the following options to manage ACD backed plex:"
        echo "Start - This will mount all drives, and start services"
        echo "Stop - This will unount all drive, and will not start services"
        echo "Restart - Will unmount all drives, mount them, and start services"
        echo "Sync - Will Sync all files in local encrypted share to ACD, remount drives, verify uploaded files, and start services"
        echo "Script not run correctly. Please run according to the instructions above!"
        exit 1
fi

if [[ $EUID -eq 0 ]]; then
   echo "Do NOT run this script as root!" 1>&2
   exit 1
fi

# Stop Services, anything we need to do will interfere
sudo systemctl stop plexmediaserver
sudo systemctl stop smb
sudo systemctl stop nmb

# Create Log for automated runs
touch $PWD/logs/ACDControl-$(date '+%F').log

## MOUNT LOCATIONS ##
ACDENCRYPTED='/home/plex/.acd'
ACDUNENCRYPTED='/home/plex/acd'
LOCALENCRYPTED='/home/plex/.local'
LOCALUNENCRYPTED='/home/plex/local'
UNIONFOLDER='/home/plex/media/'

## ENCFS OPTIONS ##
ENCFSKEY='Pass Here'
ENCFSXML='/home/plex/encfs.xml'

if [ "$1" == "Start" ]; then
echo "Start routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log
acdcli mount $ACDENCRYPTED --allow-other
        if mountpoint -q $ACDENCRYPTED; then
                sleep 3
                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $ACDENCRYPTED $ACDUNENCRYPTED
                if mountpoint -q $ACDUNENCRYPTED; then
                        sleep 3
                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $LOCALENCRYPTED $LOCALUNENCRYPTED
                        if mountpoint -q $LOCALUNENCRYPTED; then
                                sleep 3
                                unionfs-fuse -o cow,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                if mountpoint -q $UNIONFOLDER; then
                                        sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "All mounts are valid, and services have been started! (:" >> $PWD/logs/ACDControl-$(date '+%F').log
                                else
                                        echo "unionfs-fuse did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                fi
                        else
                                echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                        fi
                else
                        echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                fi
        else
                echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
        fi
else
        if [ "$1" == "Stop" ]; then
                        echo "Stop routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                echo "If mount errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                sudo umount $UNIONFOLDER
                sudo fusermount -u $LOCALUNENCRYPTED
                sudo fusermount -u $ACDUNENCRYPTED
                acdcli umount
        else
                if [ "$1" == "Restart" ]; then
                                echo "Restart routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                        echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                        echo "If mount errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                        sudo umount $UNIONFOLDER
                        sudo fusermount -u $LOCALUNENCRYPTED
                        sudo fusermount -u $ACDUNENCRYPTED
                        acdcli umount
                        sleep 3

                        acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log

                        sleep 5
                        acdcli mount $ACDENCRYPTED --allow-other
                                if mountpoint -q $ACDENCRYPTED; then
                                        sleep 3
                                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $ACDENCRYPTED $ACDUNENCRYPTED
                                        if mountpoint -q $ACDUNENCRYPTED; then
                                                sleep 3
                                                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $LOCALENCRYPTED $LOCALUNENCRYPTED
                                                if mountpoint -q $LOCALUNENCRYPTED; then
                                                        sleep 3
                                                        unionfs-fuse -o cow,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                                        if mountpoint -q $UNIONFOLDER; then
                                                                sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                echo "All mounts are valid, and services have been started! (:" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        else
                                                                echo "unionfs-fuse did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        fi
                                                else
                                                        echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                fi
                                        else
                                                echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                        fi
                                else
                                        echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                fi
                else
                        if [ "$1" == "Sync" ]; then
                                        echo "Sync routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "Clear cache..." >> $PWD/logs/ACDControl-$(date '+%F').log
                                acdcli cc
                                acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log
                                acdcli ul -x 2 -r 5 /home/plex/.local-sorted/* / >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "If mount errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo umount $UNIONFOLDER
                                        sudo fusermount -u $LOCALUNENCRYPTED
                                        sudo fusermount -u $ACDUNENCRYPTED
                                        acdcli umount
                                        sleep 3

                                        echo "Syncing new upload changes with local cache" >> $PWD/logs/ACDControl-$(date '+%F').log
                                        acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log

                                        sleep 5
                                        acdcli mount $ACDENCRYPTED --allow-other
                                                if mountpoint -q $ACDENCRYPTED; then
                                                        sleep 3
                                                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $ACDENCRYPTED $ACDUNENCRYPTED
                                                        if mountpoint -q $ACDUNENCRYPTED; then
                                                                sleep 3
                                                                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public $LOCALENCRYPTED $LOCALUNENCRYPTED
                                                                if mountpoint -q $LOCALUNENCRYPTED; then
                                                                        sleep 3
                                                                        unionfs-fuse -o cow,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                                                        if mountpoint -q $UNIONFOLDER; then
                                                                                #echo "Starting upload verification, not cutting prefix hypens, if the upload was a lot of file this can take a while" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                #echo "To watch the upload verification in real time, open another window and run tail -f" "$PWD/logs/upload-NoSed-$(date '+%F').log" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                #./NoSed-UploadVerify.sh > "logs/upload-NoSed-$(date '+%F').log" 2>&1
                                                                                echo "Removing local folders older than 2 weeks" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                find /home/plex/.local/ -type d -empty -mtime +14 -exec rm -rf {} \; >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                #echo "Starting upload verification, cutting prefix hypens, if the upload was a lot of file this can take a while" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                #echo "To watch the upload verification in real time, open another window and run tail -f" "$PWD/logs/upload-Sed-$(date '+%F').log" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                echo "Removing local files older than 2 weeks" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                find /home/plex/.local/ -type f -mtime +14 -exec rm -rf {} \; >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                #./Sed-UploadVerify.sh > "logs/upload-Sed-$(date '+%F').log" 2>&1
                                                                                sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                wget -q http://127.0.0.1:32400/library/sections/1/refresh?X-Plex-Token=Lfh9V1QQwZm5A8znsjT4 -O deleteme
                                                                                rm $PWD/deleteme
                                                                                wget -q http://127.0.0.1:32400/library/sections/2/refresh?X-Plex-Token=Lfh9V1QQwZm5A8znsjT4 -O deleteme
                                                                                rm $PWD/deleteme
                                                                                wget -q http://127.0.0.1:32400/library/sections/3/refresh?X-Plex-Token=Lfh9V1QQwZm5A8znsjT4 -O deleteme
                                                                                rm $PWD/deleteme
                                                                                echo "ACD backed Plex Sync Completed, see log for file verification!" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                        else
                                                                                echo "unionfs-fuse did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                        fi
                                                                else
                                                                        echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                fi
                                                        else
                                                                echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        fi
                                                else
                                                        echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                fi
                        fi
                fi
        fi
fi
