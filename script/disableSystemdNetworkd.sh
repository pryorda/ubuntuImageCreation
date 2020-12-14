#!/bin/bash -eux

echo "==> Remove netplan"
apt-get remove -y netplan.io

echo "==> Disable networkd"
systemctl disable systemd-networkd
systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
apt-get --assume-yes purge nplan netplan.io

echo "==> Install ifupdown"
apt-get install -y ifupdown
systemctl unmask networking
systemctl enable networking
systemctl restart networking