#!/bin/bash

systemctl enable ssh
service ssh start
#service core-daemon start
/update-custom-serivces.sh

core-daemon > /var/log/core-daemon.log 2>&1 &
dockerd > /var/log/dockerd.log 2>&1 &

if [ ! -z "$SSHKEY" ]; then
	echo "Adding ssh key: $SSHKEY"
	mkdir /root/.ssh
	chmod 755 ~/.ssh
	echo $SSHKEY > /root/.ssh/authorized_keys
    chmod 644 /root/.ssh/authorized_keys	
fi

core-gui

