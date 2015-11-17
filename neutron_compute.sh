#!/bin/bash

cat << EOF >> /etc/sysctl.conf
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

yum install -y openstack-neutron-ml2 \
  openstack-neutron-openvswitch \
  openstack-utils

NEUTRON_PASS=osneutron
NOVA_PASS=osnova
SERVICE_TENANT_ID=`keystone tenant-get service | tail -3| head -1 | cut -d"|" -f3`

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT rpc_backend rabbit
	
openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT rpc_host controller 

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT rpc_password osrabbit

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT auth_strategy keystone 

openstack-config --set /etc/neutron/neutron.conf \
	keystone_authtoken auth_uri http://controller:5000/v2.0
 
openstack-config --set /etc/neutron/neutron.conf \
	keystone_authtoken identity_uri http://controller:35357

openstack-config --set /etc/neutron/neutron.conf \
	keystone_authtoken admin_tenant_name service

openstack-config --set /etc/neutron/neutron.conf \
	keystone_authtoken admin_user neutron 

openstack-config --set /etc/neutron/neutron.conf \
	keystone_authtoken admin_password $NEUTRON_PASS 

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT core_plugin ml2 

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT service_plugins router

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT allow_overlapping_ips True 

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT verbose True 


openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ml2 type_drivers flat,gre

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ml2 tenant_network_types gre 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ml2 mechanism_drivers openvswitch 
	
openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ml2_type_gre tunnel_id_ranges 1:1000 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup enable_security_group True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup enable_ipset True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ovs local_ip 192.168.3.150

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ovs enable_tunneling True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	agent tunnel_types gre
	
systemctl enable openvswitch.service

systemctl start openvswitch.service

openstack-config --set /etc/nova/nova.conf \
  DEFAULT network_api_class nova.network.neutronv2.api.API
  
openstack-config --set /etc/nova/nova.conf \
  DEFAULT security_group_api neutron

openstack-config --set /etc/nova/nova.conf \
  DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
  
openstack-config --set /etc/nova/nova.conf \
  DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

openstack-config --set /etc/nova/nova.conf \
  neutron url http://controller:9696

openstack-config --set /etc/nova/nova.conf \
  neutron auth_strategy keystone

openstack-config --set /etc/nova/nova.conf \
  neutron admin_auth_url http://controller:35357/v2.0
  
openstack-config --set /etc/nova/nova.conf \
  neutron admin_tenant_name service
  
openstack-config --set /etc/nova/nova.conf \
  neutron admin_username neutron
  
openstack-config --set /etc/nova/nova.conf \
  neutron admin_password  $NEUTRON_PASS
  
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

cp /usr/lib/systemd/system/neutron-openvswitch-agent.service \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
  
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service
  
systemctl restart openstack-nova-compute.service

systemctl enable neutron-openvswitch-agent.service

systemctl start neutron-openvswitch-agent.service

source admin-openrc.sh

neutron agent-list
