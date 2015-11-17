#!/bin/bash

cat << EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

yum install -y openstack-neutron \
	openstack-neutron-ml2 \
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
	ml2_type_flat flat_networks external

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ml2_type_gre tunnel_id_ranges 1:1000 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup enable_security_group True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup enable_ipset True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ovs local_ip 192.168.3.140

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ovs enable_tunneling True 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	ovs bridge_mappings external:br-ex 

openstak-config --set /etc/neutron/plugins/ml2/ml2_conf.ini \
	agent tunnel_types gre

openstak-config --set /etc/neutron/l3_agent.ini \
	DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver 

openstak-config --set /etc/neutron/l3_agent.ini \
	DEFAULT use_namespaces True 

openstak-config --set /etc/neutron/l3_agent.ini \
	DEFAULT external_network_bridge br-ex 

openstak-config --set /etc/neutron/l3_agent.ini \
	DEFAULT router_delete_namespaces True 

openstak-config --set /etc/neutron/l3_agent.ini \
	DEFAULT verbose True 

openstak-config --set /etc/neutron/dhcp_agent.ini \
	DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver 

openstak-config --set /etc/neutron/dhcp_agent.ini \
	DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq 

openstak-config --set /etc/neutron/dhcp_agent.ini \
	DEFAULT use_namespaces True 

openstak-config --set /etc/neutron/dhcp_agent.ini \
	DEFAULT  dhcp_delete_namespaces True

openstak-config --set /etc/neutron/dhcp_agent.ini \
	DEFAULT  verbose True

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT auth_url http://controller:5000/v2.0

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT auth_region regionOne

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT admin_tenant_name service

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT admin_user neutron

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT admin_password $NEUTRON_PASS 

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT nova_metadata_ip controller 

openstak-config --set /etc/neutron/metadata_agent.ini \
	DEFAULT verbose True 


systemctl restart openstack-nova-api.service

systemctl enable openvswitch.service

systemctl start openvswitch.service

ovs-vsctl add-br br-ex

echo "Please enter a network interface name which connected to external network examples(ethx/ensx etc...)\n"
read INTERFACE_NAME
ovs-vsctl add-port br-ex $INTERFACE_NAME

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

cp /usr/lib/systemd/system/neutron-openvswitch-agent.service \
	/usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
	
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' \
	/usr/lib/systemd/system/neutron-openvswitch-agent.service

systemctl enable neutron-openvswitch-agent.service \
	neutron-l3-agent.service \
	neutron-dhcp-agent.service \
	neutron-metadata-agent.service \
	neutron-ovs-cleanup.service
	
systemctl start neutron-openvswitch-agent.service \
	neutron-l3-agent.service \
	neutron-dhcp-agent.service \
	neutron-metadata-agent.service \
	neutron-ovs-cleanup.service


source admin-openrc.sh

neutron agent-list
