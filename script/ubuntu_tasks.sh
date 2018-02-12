#!/bin/bash

echo "==> Ubuntu Tasks"

echo "===> Creating ubuntu user"
useradd -m -G sudo -s /bin/bash ubuntu
mkdir /home/ubuntu/.ssh
echo "====> Creating ubuntu will use key ${ubuntu_authorized_key}"
echo "${ubuntu_authorized_key}" > /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod -R go-rwx /home/ubuntu/.ssh
echo "==> Setting ubuntu password"
[ -z ${ubuntu_password} ] && echo "ubuntu_password not defined" >&2 && exit 1
echo "ubuntu:${ubuntu_password}" | chpasswd

echo "===> Updating sudoers"
echo "ubuntu        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu

echo "===> Configure cron to remove vagrant user at reboot"
echo "@reboot /root/removeVagrant.sh" | crontab -
mv /home/vagrant/removeVagrant.sh /root/
chmod u+x /root/removeVagrant.sh

echo "===> Removing vboxadd user"
userdel -r -f vboxadd

echo "===> Removing swap device"
SWAP_DEVICE="$(/sbin/blkid -t TYPE=swap -o device)"
swapoff --all
lvremove -f ${SWAP_DEVICE}
ESCAPED_DEVICE=$( echo "${SWAP_DEVICE}" | sed 's/\//\\\//g' )
sed -i "/${ESCAPED_DEVICE}/d" /etc/fstab
