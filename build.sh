#!/bin/bash -e

# On the esx host configure firewall rules for vnc: https://platform9.com/support/enable-vnc-on-vmware-deployments/
PACKER_ESXI_VNC_PROBE_TIMEOUT=2s

set -x
export VMWARE_SSH_USER=${VMWARE_SSH_USER:-"root"}
export VMWARE_DATASTORE=${VMWARE_DATASTORE:-"tools"}
export VIRTUAL_MACHINE_NAME=${VIRTUAL_MACHINE_NAME:-"Ubuntu-18.04"}
export VIRTUAL_MACHINE_VERSION=${VIRTUAL_MACHINE_VERSION:-"v1"}
export VIRTUAL_MACHINE_NAME="${VIRTUAL_MACHINE_NAME}-${VIRTUAL_MACHINE_VERSION}"
export VCENTER_HOST=${VCENTER_HOST:-"vcenter.pryorda.dok"}
export SSH_KEY_FILE=${SSH_KEY_FILE:-"${HOME}/.ssh/id_rsa"}
export OUTPUT_DIR="${OUTPUT_DIR:-"packer-output-${VIRTUAL_MACHINE_NAME}"}"
export REMOTE_BUILD_HOST=${REMOTE_BUILD_HOST:-"vmware-hypervisor1.pryorda.dok"}
export VMWARE_NETWORK=${VMWARE_NETWORK:-"VM Network"}
set +x

# Enable Logging:
# export PACKER_LOG=1

if [ -z ${PACKER_UBUNTU_PASSWORD} ]; then
    echo "PACKER_UBUNTU_PASSWORD not defined.  Please export this variable to set required ubuntu user password"
    exit 1
fi

if [ -z ${VMWARE_SSH_PASSWORD} ]; then
    echo "VMWARE_SSH_PASSWORD not defined.  Please export this variable to set required password"
    exit 1
fi

if [ -z ${VMWARE_SSH_USER} ]; then
    echo "VMWARE_SSH_USER not defined.  Please export this variable to set required user"
    exit 1
fi

if [ -z ${PACKER_UBUNTU_AUTHORIZED_KEY} ] || [ ! -f ${PACKER_UBUNTU_AUTHORIZED_KEY} ]; then
    echo "PACKER_UBUNTU_AUTHORIZED_KEY not defined or set to a non-existant file."
    echo "Please export this variable to point to a public key file that will be "
    echo "placed in the ubuntu users authorized keys."
    echo "${PACKER_UBUNTU_AUTHORIZED_KEY}"
    exit 1
fi

export UBUNTU_AUTHORIZED_KEY="$(cat ${PACKER_UBUNTU_AUTHORIZED_KEY})"
echo "UBUNTU_AUTHORIZED_KEY=${UBUNTU_AUTHORIZED_KEY}"
echo "==> Building ESX (vmware-iso) VM ${VIRTUAL_MACHINE_NAME}"
packer build --only=vmware-iso ubuntu.json

echo '==> Copy shrinkdisk.sh to host'
sshpass -e scp -i ${SSH_KEY_FILE} -o 'StrictHostKeyChecking=no' shrinkdisk.sh ${VMWARE_SSH_USER}@${REMOTE_BUILD_HOST}:/tmp/shrinkdisk.sh
echo '==> Shrink disk'
sshpass -e ssh -i ${SSH_KEY_FILE} -o 'StrictHostKeyChecking=no' ${VMWARE_SSH_USER}@${REMOTE_BUILD_HOST} "export VMWARE_DATASTORE=${VMWARE_DATASTORE} && export OUTPUT_DIR=${OUTPUT_DIR} && sh /tmp/shrinkdisk.sh"
