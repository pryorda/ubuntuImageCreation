#!/usr/bin/ruby

require 'yaml'
require 'erb'
require 'ostruct'

net_plan_yaml = YAML.load(IO.read('netplan/99-vmware-esx.yaml'))
interfaces = net_plan_yaml['network']['ethernets']
template = IO.read('template.erb')

class ErbalT < OpenStruct
  def self.render_from_hash(t, h)
    ErbalT.new(h).render(t)
  end

  def render(template)
    ERB.new(template, nil, '-').result(binding)
  end
end

interfaces.each do |interface, interface_data|
  vars = { 'interface' => interface, 'interface_data' => interface_data }
  puts ErbalT.render_from_hash(template, vars)
end
