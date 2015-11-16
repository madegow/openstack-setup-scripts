#!/bin/bash

MYSQL=`which mysql`

QUERY_DBCREATE="CREATE DATABASE IF NOT EXIST neutron;"

QUERY_GRANT_PRIVILEGES_LOCALHOST="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'dbneutron';"

QUERY_GRANT_PRIVILEGES_REST="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'dbneutron';"

$MYSQL -uroot -p -e "$QUERY_DBCREATE"
$MYSQL -uroot -p -e "$QUERY_GRANT_PRIVILEGES_LOCALHOST"
$MYSQL -uroot -p -e "$QUERY_GRANT_PRIVILEGES_REST"

source admin-openrc.sh

NEUTRON_PASS=osneutron
NOVA_PASS=osnova
SERVICE_TENANT_ID=`keystone tenant-get service | tail -3| head -1 | cut -d"|" -f3`
keystone user-create --name neutron \
	--pass $NEUTRON_PASS

keystone user-role-add --user neutron \
	--tenant service \
	--role admin

keystone service-create --name neutron \
	--type network \
	--description "OpenStack Networking " 

keystone endpoint-create \
	--service-id $(keystone service-list | awk '/ network / {print $2}') \
	--publicurl http://controller:9696 \
	--adminurl http://controller:9696 \
	--internalurl http://controller:9696 \
	--region regionOne

yum install -y openstack-neutron \
	openstack-neutron-ml2 \
	python-neutronclient \
	which

openstack-config --set /etc/neutron/neutron.conf \
	database connection mysql://neutron:dbneutron@controller/neutron 

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
	DEFAULT  notify_nova_on_port_status_changes True

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT notify_nova_on_port_data_changes True

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_url http://controller:8774/v2

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_admin_auth_url http://controller:35357/v2.0

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_region_name regionOne

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_admin_username nova

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_admin_tenant_id $SERVICE_TENANT_ID

openstack-config --set /etc/neutron/neutron.conf \
	DEFAULT nova_admin_password $NOVA_PASS

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

openstak-config --set /etc/nova/nova.conf \
	DEFAULT network_api_class nova.network.neutronv2.api.API

openstak-config --set /etc/nova/nova.conf \
	DEFAULT security_group_api neutron 
openstak-config --set /etc/nova/nova.conf \
	DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver 
openstak-config --set /etc/nova/nova.conf \
	DEFAULT	firewall_driver nova.virt.firewall.NoopFirewallDriver 

openstak-config --set /etc/nova/nova.conf \
	neutron	url http://controller:9696 

openstak-config --set /etc/nova/nova.conf \
	neutron auth_strategy keystone	 

openstak-config --set /etc/nova/nova.conf \
	neutron admin_auth_url http://controller:35357/v2.0 

openstak-config --set /etc/nova/nova.conf \
	neutron admin_tenant_name service 

openstak-config --set /etc/nova/nova.conf \
	neutron admin_username neutron 

openstak-config --set /etc/nova/nova.conf \
	neutron admin_password $NEUTRON_PASS 


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage \
	--config-file /etc/neutron/neutron.conf \
	--config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
	upgrade juno" neutron

systemctl restart openstack-nova-api.service \
	openstack-nova-scheduler.service \
	openstack-nova-conductor.service

systemctl enable neutron-server.service

systemctl start neutron-server.service

neutron ext-list

#verifying after sucessfully configuring network node

#source admin-openrc.sh

#nova service-list

#nova image-list
