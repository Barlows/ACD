#!/bin/sh

/bin/fusermount -uz /home/plex/acd
/bin/fusermount -uz /home/plex/.acd
/bin/fusermount -uz /home/plex/local
/bin/fusermount -uz /home/plex/.local
/bin/fusermount -uz /home/plex/media

/usr/local/bin/acdcli sync

/usr/local/bin/acdcli mount -ro /home/plex/.acd

ENCFS6_CONFIG='/home/plex/encfs.xml' encfs --extpass="cat /home/plex/scripts/encfspass" /home/plex/.acd /home/plex/acd

ENCFS6_CONFIG='/home/plex/encfs.xml' encfs --extpass="cat /home/plex/scripts/encfspass" /home/plex/.local /home/plex/local

unionfs-fuse -o cow /home/plex/local=RW:/home/plex/acd=RO /home/plex/media

exit
