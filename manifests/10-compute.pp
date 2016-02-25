node /compute[0-9]*/{


  # Network interface setting  
  class { '::network_config':
    ip_ranges => hiera('ip_ranges'),
    subnets => hiera('subnets'),
    interface_lists => hiera('interface_lists'),
    dnss => hiera('dns')
  }
  
  class { '::compute_node':
    ovs_external_ip => $::network_config::ip_admin,
    manage_ip => $::network_config::ip_manage
  }
  
}
