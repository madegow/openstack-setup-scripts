#!/bin/bash

MYSQL=`which mysql`

QUERY_DBCREATE="CREATE DATABASE IF NOT EXIST nova;"
QUERY_GRANT_PRIVILEGES_LOCALHOST="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'dbnova';"
QUERY_GRANT_PRIVILEGES_REST="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'dbnova';"

$MYSQL -uroot -p -e "$QUERY_DBCREATE"
$MYSQL -uroot -p -e "$QUERY_GRANT_PRIVILEGES_LOCALHOST"
$MYSQL -uroot -p -e "$QUERY_GRANT_PRIVILEGES_REST"

source admin-openrc.sh

NOVA_PASS=osnova

keystone user-create --name nova \
	--pass $NOVA_PASS

keystone user-role-add --user nova \
	--tenant service \
	--role admin

keystone service-create --name nova \
	--type compute \
	--description "OpenStack Compute"

keystone endpoint-create \
	--service-id $(keystone service-list | awk '/ compute / {print $2}') \
	--publicurl http://controller:8774/v2/%\(tenant_id\)s \
	--internalurl http://controller:8774/v2/%\(tenant_id\)s \
	--adminurl http://controller:8774/v2/%\(tenant_id\)s \
	--region regionOne

yum install -y openstack-nova-api \
	openstack-nova-cert \
	openstack-nova-conductor \
	openstack-nova-console \
	openstack-nova-novncproxy \
	openstack-nova-scheduler \
	python-novaclient

openstack-config --set /etc/nova/nova.conf \
	database connection mysql://nova:dbnova@controller/nova 

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
	DEFAULT my_ip 192.168.2.130 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT vncserver_listen  192.168.2.130 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT vncserver_proxyclient_address  192.168.2.130 

openstack-config --set /etc/nova/nova.conf \
	DEFAULT verbose True 

openstack-config --set /etc/nova/nova.conf \
	glance host controller 

/bin/sh -c "nova-manage db sync" nova

systemctl enable openstack-nova-api.service \
	openstack-nova-cert.service \
	openstack-nova-consoleauth.service \
	openstack-nova-scheduler.service \
	openstack-nova-conductor.service \
	openstack-nova-novncproxy.service

systemctl start openstack-nova-api.service \
	openstack-nova-cert.service \
	openstack-nova-consoleauth.service \
	openstack-nova-scheduler.service \
	openstack-nova-conductor.service \
	openstack-nova-novncproxy.service

#verifying after sucessfully configuring compute node

#source admin-openrc.sh

#nova service-list

#nova image-list
