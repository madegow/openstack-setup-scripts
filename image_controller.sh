ADMIN_TOKEN=2c71e31aba6153a94c04
ADMIN_PASS=osadmin
DEMO_PASS=osdemo
EMAIL_ADDRESS="shivakumara.madegowda@gmail.com"

export OS_SERVICE_TOKEN=2c71e31aba6153a94c04
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0
GLANCE_PASS=osglance

source admin-openrc.sh

keystone user-create --name glance --pass $GLANCE_PASS
keystone user-role-add --user glance --tenant service --role admin
keystone service-create --name glance --type image --description "OpenStack Image Service"
keystone endpoint-create --service-id $(keystone service-list | awk '/ image / {print $2}') --publicurl http://controller:9292 --internalurl http://controller:9292 --adminurl http://controller:9292 --region regionOne

yum install openstack-glance python-glanceclient

openstack-config --set /etc/glance/glance-api.conf database  connection mysql://glance:dbglance@controller/glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  auth_uri http://controller:5000/v2.0
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  identity_uri http://controller:35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  admin_tenant_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  admin_user glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  admin_password $GLANCE_PASS 
openstack-config --set /etc/glance/glance-api.conf paste_deploy  flavor keystone 

openstack-config --set /etc/glance/glance-api.conf glance_store  default_store file 
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images 

openstack-config --set /etc/glance/glance-api.conf DEFAULT  notification_driver noop 
openstack-config --set /etc/glance/glance-api.conf DEFAULT  verbose True 

openstack-config --set /etc/glance/glance-registry.conf databse connection mysql://glance:dbglance@controller/glance 
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  auth_uri http://controller:5000/v2.0
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  identity_uri http://controller:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  admin_tenant_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  admin_user glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  admin_password $GLANCE_PASS 
openstack-config --set /etc/glance/glance-registry.conf paste_deploy  flavor keystone 

openstack-config --set /etc/glance/glance-registry.conf DEFAULT  notification_driver noop 
openstack-config --set /etc/glance/glance-registry.conf DEFAULT  verbose True 

/bin/sh -c "glance-manage db_sync" glance

systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

mkdir /tmp/images
wget -P /tmp/images http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
source admin-openrc.sh
glance image-create --name "cirros-0.3.3-x86_64" --file /tmp/images/cirros-0.3.3-x86_64-disk.img --disk-format qcow2 --container-format bare --is-public True --progress
glance image-list
