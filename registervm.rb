#!/usr/bin/ruby

require 'rbvmomi'

# Only supports vcenter currently

vmware_ssh_user = ENV['VMWARE_SSH_USER'] \
  || raise("Set VMWARE_SSH_USER environment variable")
puts "Using user: #{ENV['VMWARE_SSH_USER']}"

virtual_machine_name = ENV['VIRTUAL_MACHINE_NAME'] \
  || raise("Set VIRTUAL_MACHINE_NAME environment variable")
puts "Virtual Machine Name: #{ENV['VIRTUAL_MACHINE_NAME']}"

vmware_ssh_password = ENV['VMWARE_SSH_PASSWORD'] \
  || raise("Set VMWARE_SSH_PASSWORD environment variable")

vcenter_host = ENV['VCENTER_HOST'] \
  || raise("Set VCENTER_HOST environment variable")

output_directory = ENV['OUTPUT_DIR'] \
  || raise("Set OUTPUT_DIR environment variable")

vmware_datastore = = ENV['VMWARE_DATASTORE'] \
  || raise("Set VMWARE_DATASTORE environment variable")


datacenters = ['vmware-datacenters']

# Functions
# find_vmx_files: find files in a datacenter takes datastore and directory path
def find_vmx_files(ds, output_directory) # rubocop:disable Metrics/MethodLength
  datastore_path = "[#{ds.name}] /#{output_directory}"
  puts datastore_path
  search_spec = {
    details: { fileOwner: false, fileSize: false, fileType: true,
               modification: false },
    query: [
      RbVmomi::VIM::VmConfigFileQuery(), RbVmomi::VIM::TemplateConfigFileQuery()
    ]
  }
  task = ds.browser.SearchDatastoreSubFolders_Task(datastorePath: datastore_path,
                                                   searchSpec: search_spec)

  results = task.wait_for_completion

  files = []
  results.each do |result|
    result.file.each do |file|
      files << "#{result.folderPath}/#{file.path}"
    end
  end

  files
end

# find_datastore: find datastore in datacenter by dsName
def find_datastore(datacenter, ds_name)
  dc = datacenter
  base_entity = dc.datastore
  base_entity.find { |f| f.info.name == ds_name } \
    || abort("no such datastore #{ds_name}")
end

# find_compute_resources: find all compute resources in a folder.
def find_compute_resources(folder)
  retval = []
  children = folder.children.find_all
  children.each do |child|
    if child.class == RbVmomi::VIM::ComputeResource
      retval << child
    elsif child.class == RbVmomi::VIM::ClusterComputeResource
      child.host.each do |h|
        retval << h
      end
    elsif child.class == RbVmomi::VIM::Folder
      retval.concat(find_computer_resources(child))
    end
  end
  retval
end

# find_available_hosts: finds all hosts that can be used by the virtual machine.
# this just checks to see if the datastore is available on the host. takes
# folder and datacenter
# returns hosts
def find_available_hosts(folder, datastore)
  hosts = find_compute_resources(folder)
  hosts.reject! { |host| !host.datastore.include?(datastore) }
  hosts
end

# Connection and Get Templates folder
vim = RbVmomi::VIM.connect(host: vcenter_host, user: vmware_ssh_user, \
                           password: vmware_ssh_password, insecure: true)

dc = vim.serviceInstance.find_datacenter(datacenters[0]) \
    || raise('datacenter not found')
folder = dc.find_folder('Templates')

# clean up Discoverd virtual machine orphan
discovered_vms_folder = dc.find_folder('Discovered virtual machine')
discovered_vms_folder.childEntity.each do |vm|
  if vm.name.include?(virtual_machine_name)
    puts "Unregistering orphaned VM: #{vm.name}"
    vm.UnregisterVM
  end
end

# Get resource pool, host, datastore, and cluster
ds = find_datastore(dc, 'tools')
host = find_available_hosts(dc.hostFolder, ds)[0] # Grab the 1st available host
cluster = dc.hostFolder.childEntity[0] # grab the first datacenter
rp = cluster.resourcePool


puts "Cluster: #{cluster.name}"
puts "Host: #{host.name}"
puts "Resource Pool: #{rp.name}"
puts "Datastore: #{ds.name}"
vmx_file = find_vmx_files(ds, output_directory)[0]
puts "Registering File: #{vmx_file}"

begin
  folder.RegisterVM_Task(path: vmx_file, asTemplate: true,
                         host: host).wait_for_completion
rescue => error
  puts "Failed to register with error: #{error}" if error
end
