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

  include ::controller_node
}

