ADMIN_TOKEN=2c71e31aba6153a94c04
ADMIN_PASS=osadmin
DEMO_PASS=osdemo
EMAIL_ADDRESS="shivakumara.madegowda@gmail.com"

export OS_SERVICE_TOKEN=2c71e31aba6153a94c04
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0

function execute(){
	echo "done with execute"
	openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token 2c71e31aba6153a94c04 
	openstack-config --set /etc/keystone/keystone.conf DEFAULT verbose True 
	openstack-config --set /etc/keystone/keystone.conf database  connection mysql://keystone:dbkeystone@controller/keystone
	openstack-config --set /etc/keystone/keystone.conf provider keystone.token.providers.uuid.Provider 
	openstack-config --set /etc/keystone/keystone.conf driver keystone.token.persistence.backends.sql.Token
	openstack-config --set /etc/keystone/keystone.conf revoke keystone.contrib.revoke.backends.sql.Revoke
	keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
	chown -R keystone:keystone /var/log/keystone
	chown -R keystone:keystone /etc/keystone/ssl
	chmod -R o-rwx /etc/keystone/ssl
	/bin/sh -c "keystone-manage db_sync" keystone
	systemctl enable openstack-keystone.service
	systemctl start openstack-keystone.service
	
	(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone
	
	keystone tenant-create --name admin --description "Admin Tenant"
	keystone user-create --name admin --pass $ADMIN_PASS --email $EMAIL_ADDRESS
	keystone role-create --name admin
	keystone user-role-add --user admin --tenant admin --role admin
	keystone tenant-create --name demo --description "Demo Tenant"
	keystone user-create --name demo --tenant demo --pass $DEMO_PASS --email $EMAIL_ADDRESS
	keystone tenant-create --name service --description "Service Tenant"
	keystone service-create --name keystone --type identity --description "OpenStack Identity"

	keystone endpoint-create --service-id $(keystone service-list | awk '/ identity / {print $2}') --publicurl http://controller:5000/v2.0 --internalurl http://controller:5000/v2.0 --adminurl http://controller:35357/v2.0 --region regionOne
	
	unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
	
	keystone --os-tenant-name admin --os-username admin --os-password $ADMIN_PASS --os-auth-url http://controller:35357/v2.0 token-get
	keystone --os-tenant-name admin --os-username admin --os-password $ADMIN_PASS --os-auth-url http://controller:35357/v2.0 tenant-list
	keystone --os-tenant-name admin --os-username admin --os-password $ADMIN_PASS  --os-auth-url http://controller:35357/v2.0 user-list
	keystone --os-tenant-name admin --os-username admin --os-password $ADMIN_PASS  --os-auth-url http://controller:35357/v2.0 role-list
	keystone --os-tenant-name demo --os-username demo --os-password $DEMO_PASS --os-auth-url http://controller:35357/v2.0 token-get

	keystone --os-tenant-name demo --os-username demo --os-password $DEMO_PASS --os-auth-url http://controller:35357/v2.0 user-list
}
yum install -y openstack-keystone python-keystoneclient
yum install -y openstack-utils	
execute
