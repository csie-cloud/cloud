# $domain = "cloud.csie.ntu.edu.tw" which is got from creator's domain!! 

node /controller[1-3]/{


  # Network interface setting
  
  $subnets = hiera('subnets')
  $host_type = $hostname.match(/^[a-z]*/)[0]
  $ip = hiera('ip_ranges')[$host_type] + $hostname.match(/\d$/)[0]
  
  notify{ 'hostname':
    message => " Hostname: ${hostname}, Host Type: ${host_type}, IP surfix: $ip"
  }

  class { 'network::global':
    vlan => 'yes',
  }
  
  network::if::static { 'eno1':
    ensure    => 'up',
    dns1 => hiera('dns')[0],
    peerdns => true,
    domain => $domain,
    ipaddress => "${subnets['admin']['prefix']}.${ip}",
    netmask   => $subnets['admin']['mask']
  }
  
  network::if::static { 'eno2':
    ensure => 'up',
    ipaddress => "${subnets['external']['prefix']}.${ip}",
    netmask   => $subnets['external']['mask'],
    gateway => $subnets['external']['gateway']
  }

  network::if::static { 'eno2.42':
    ensure => 'up',
    ipaddress => "${subnets['manage']['prefix']}.${ip}",
    netmask   => $subnets['manage']['mask']
  }

  network::if::static { 'eno2.41':
    ensure => 'up',
    ipaddress => "${subnets['storage']['prefix']}.${ip}",
    netmask   => $subnets['storage']['mask']
  }


  # Keystone
  include ::password
  Exec { logoutput => 'on_failure' }

  class { '::mysql::server': }
  
  class { '::keystone::db::mysql':
    password => $::password::keystone_db,
    allowed_hosts => 'localhost'
  }
  
  package{'centos-release-openstack-liberty':
    ensure => present
  }
  
  class { '::keystone':
    verbose             => true,
    debug               => true,
    database_connection => "mysql://keystone:${::password::keystone_db}@localhost/keystone",
    admin_token         => $::password::keystone_token,
    catalog_type        => 'sql',
    enabled             => false, # service openstack-keystone should never be started.
    service_name => "httpd",
    require => Package['centos-release-openstack-liberty']
  }
  
  class { '::keystone::roles::admin':
    email => 'admin@cloud.csie.ntu.edu.tw',
    password            => $::password::user_admin,
  }
  
  class { '::keystone::endpoint':
    public_url => "http://${hostname}:5000",
    admin_url  => "http://${hostname}-admin:35357",
    internal_url => "http://${hostname}-int:5000",
    region => 'RegionOne'
  }


  include ::apache

  class { '::keystone::wsgi::apache':
    ssl         => false,
    public_port => 5000,
    admin_port  => 35357,
  }
  
  keystone_tenant { 'service':
    ensure => present
  }

  keystone_tenant { 'admin':
    ensure => present
  }
  
  keystone_user_role { 'admin::default@admin::default':
    ensure => present,
    roles  => ['admin']
  }  

  keystone_tenant { 'demo':
    ensure => present,
  }

  
  keystone_user { 'demo':
    ensure => present,
    enabled => true,
    password => $::password::user_demo
  }

  keystone_role { 'user':
    ensure => present,
  }
  
  keystone_user_role { 'admin::default@demo::default':
    ensure => present,
    roles  => ['user']
  }  
  
  
  # include keystone::disable_admin_token_auth
}

node default{
}
