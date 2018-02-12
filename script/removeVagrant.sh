#!/bin/bash

/usr/sbin/userdel -f -r vagrant
rm /etc/sudoers.d/vagrant
crontab -l | grep -v "@reboot" | crontab -

rm ${0}

