# $domain = "cloud.csie.ntu.edu.tw" which is got from creator's domain!! 


node /controller[1-3]/{


  # Network interface setting  
  class { '::network_config':
    ip_ranges => hiera('ip_ranges'),
    subnets => hiera('subnets'),
    interface_lists => hiera('interface_lists'),
    dnss => hiera('dns')
  }
  
  class { '::controller_node':
    ovs_external_ip => $::network_config::ip_admin
  }
}

