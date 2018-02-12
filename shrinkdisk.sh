#!/bin/bash

cd /vmfs/volumes/${VMWARE_DATASTORE}/${OUTPUT_DIR}
vmkfstools -i disk.vmdk -d thin thindisk.vmdk
vmkfstools --punchzero thindisk.vmdk
vmkfstools -E disk.vmdk orig-disk.vmdk
vmkfstools -E thindisk.vmdk disk.vmdk
rm -f orig-disk*
