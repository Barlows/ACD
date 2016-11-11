mkdir /home/plex/.acd
mkdir /home/plex/acd
mkdir /home/plex/.local
mkdir /home/plex/local
mkdir /home/plex/media
mkdir /home/plex/scripts
mkdir /home/plex/scripts/logs
wget -O /home/plex/encfs.xml http://192.168.0.252/encfs.xml
wget -O /home/plex/scripts/encfspass http://192.168.0.252/encfpass
sudo apt-get install -y python3-pip
sudo pip3 install --upgrade git+https://github.com/yadayada/acd_cli.git
sudo apt-get install -y encfs
sudo apt-get install -y unionfs-fuse
sudo apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.820_all.deb
sudo dpkg --install webmin_1.820_all.deb

exit
