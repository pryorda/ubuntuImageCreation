#!/bin/bash -eux

SSH_USERNAME=${SSH_USERNAME:-vagrant}

function install_open_vm_tools {
    echo "==> Installing Open VM Tools"
    # Install open-vm-tools so we can mount shared folders
    apt-get install -y open-vm-tools
    # Install open-vm-tools-desktop so we can copy/paste, resize, etc.
    if [[ "$DESKTOP" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
        apt-get install -y open-vm-tools-desktop
    fi
    # Add /mnt/hgfs so the mount works automatically with Vagrant
    mkdir /mnt/hgfs
}

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
    KERNEL_VERSION=$(uname -r | cut -d. -f1-2)
    echo "==> Kernel version ${KERNEL_VERSION}"
    install_open_vm_tools
    # Create symlink for /etc/dhcp3 to /etc/dhcp
    ln -s /etc/dhcp /etc/dhcp3
fi
