# A lot of this is from boxcutter - https://github.com/boxcutter/ubuntu

# Dependencies

1. Packer
2. Ruby and rbvmomi (apt install -y ruby reby-dev && gem install rbvmomi)
3. Remote ESX host to build image on
 1. Update firewall rules on node: https://platform9.com/support/enable-vnc-on-vmware-deployments/
 2. Enable GuestIP: esxcli system settings advanced set -o /Net/GuestIPHack -i 1
 3. copy ssh key to host:/etc/key-${USERNAME}/authorized_keys

# Usage

Set required environment variables

```

export VMWARE_SSH_PASSWORD='password!'
export VMWARE_SSH_USER='root'
export PACKER_UBUNTU_PASSWORD='password'
export PACKER_UBUNTU_AUTHORIZED_KEY=keyfile
```

To create the 16.04 image, run './build.sh && ./registervm.rb'

To change the provisioning of the image, update 'script/ubuntu_tasks.sh'

# Info

The script has 5 steps. They are:
1. Download ISO to packer_cache on remote host
2. Create VM
3. Run the from "scripts": [] in ubuntu.json
4. Shrink disk
5. Register with vmware with specific version (This is now done via registervm.rb)
6. ToDo Clean Up: Dangling Resources
7. Currently you have to convert the tempate to a vm, bump the compatibility, and back to a template to get it to work with terraform cloning. I will update the registervm.rb to handle this at somepoint

# Output
The output will be in datastore tools/output-build dir and will be registered as build vm

# ToDo

1. Recreate vagrant Resources
2. Automate the provisioning.
3. Make everything smarter.
