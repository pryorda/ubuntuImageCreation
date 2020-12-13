#!/bin/bash -eux

echo "==> Remove netplan"
apt-get remove -y netplan.io nplan

echo "==> Disable networkd"
systemctl disable systemd-networkd.service
systemctl disable networkd-dispatcher.service

echo "==> Install ifupdown"
apt-get install -y ifupdown
