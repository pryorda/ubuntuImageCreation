#!/bin/bash -eux

echo "==> Ubuntu Tasks"
echo "===> Update apt"
apt-get update

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
if [ ! -z "${SWAP_DEVICE}" ]; then
  swapoff --all
  lvremove -f ${SWAP_DEVICE}
  ESCAPED_DEVICE=$( echo "${SWAP_DEVICE}" | sed 's/\//\\\//g' )
  sed -i "/${ESCAPED_DEVICE}/d" /etc/fstab
fi

echo "===> Configure sshd"
sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

echo "===> Disable IPv6"
echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.d/10-disable-ipv6.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.d/10-disable-ipv6.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.d/10-disable-ipv6.conf

echo "===> Creating interfaces.d directory"
mkdir -p /etc/network/interfaces.d/

echo "===> Remove old netplan file (vmware customization workaround)"
rm -v /etc/netplan/01-netcfg.yaml