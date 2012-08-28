#
# Cookbook Name:: nova
# Recipe:: ovs
#
# Copyright 2010, 2011 Opscode, Inc.
# Copyright 2011 Dell, Inc.
# Copyright 2012 Dell, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

[ "linux-headers-#{`uname -r`.strip}",
  "openvswitch-switch",
  "openvswitch-datapath-dkms"
].map { |pkg| package(pkg) }

service "libvirt-bin" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

cookbook_file "/etc/libvirt/qemu.conf" do
  source "qemu.conf"
  mode "0644"
  notifies :restart, "service[libvirt-bin]", :immediately
end

# use crowbar_network for ovs
network = node[:nova][:ovs_network]
addr = node[:crowbar_wall][:network][:addrs][network]
iface = node[:crowbar_wall][:network][:nets][network].first
mask = addr.split('/').last

bash "enable_ovs" do
  code <<-EOH
ovs-vsctl -- --may-exist add-br br-int
ovs-vsctl -- --may-exist add-port br-int $IFACE
ip link set br-int up || true
ip addr add $ADDR dev br-int || true
ip route delete $ROUTE dev $IFACE || true
EOH
  environment({
    'IFACE' => iface,
    'ADDR' => addr,
    'ROUTE' => "#{node[:crowbar][:network][network][:subnet]}/#{mask}"
  })
end
