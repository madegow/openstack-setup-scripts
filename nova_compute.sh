#!/bin/bash

NOVA_PASS=osnova

yum install -y openstack-nova-compute \
	sysfsutils

openstack-config --set /etc/nova/nova.conf \
	DEFAULT rpc_backend rabbit
	
openstack-config --set /etc/nova/nova.conf \
	DEFAULT rpc_host controller 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT rpc_password osrabbit

openstack-config --set /etc/nova/nova.conf \
	DEFAULT auth_strategy keystone 

openstack-config --set /etc/nova/nova.conf \
	keystone_authtoken auth_uri http://controller:5000/v2.0
 
openstack-config --set /etc/nova/nova.conf \
	keystone_authtoken identity_uri http://controller:35357

openstack-config --set /etc/nova/nova.conf \
	keystone_authtoken admin_tenant_name service

openstack-config --set /etc/nova/nova.conf \
	keystone_authtoken admin_user nova 

openstack-config --set /etc/nova/nova.conf \
	keystone_authtoken admin_password $NOVA_PASS 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT my_ip 192.168.2.150 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT vnc_enabled  True 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT vncserver_listen  0.0.0.0 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT vncserver_proxyclient_address  192.168.2.150 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT novncproxy_base_url http://controller:6080/vnc_auto.html   

openstack-config --set /etc/nova/nova.conf \
	glance host controller 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT verbose True 

openstack-config --set /etc/nova/nova.conf \
	libvirt virt_type qemu 

systemctl enable \
	libvirtd.service \
	openstack-nova-compute.service

systemctl start \
	libvirtd.service \
	openstack-nova-compute.service

