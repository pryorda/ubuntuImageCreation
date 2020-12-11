#!/bin/bash -eux

echo "==> Remove netplan"
apt-get remove -y netplan.io

echo "==> Disable networkd"
systemctl disable systemd-networkd

echo "==> Install ifupdown"
apt-get install -y ifupdown
