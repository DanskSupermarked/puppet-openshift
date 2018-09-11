# Class: openshift::firewall
# ===========================
#
# Authors
# -------
#
# Benjamin Merot <benjamin.merot@dsg.dk>
#
# Copyright
# ---------
#
# Copyright 2017 Dansk Supermarked.
#
class openshift::firewall inherits openshift {

  firewall { '600 accept OS_FIREWALL_ALLOW':
    chain => 'INPUT',
    jump  => 'OS_FIREWALL_ALLOW',
    proto => 'all',
  }

  firewall { '601 accept output KUBE-FIREWALL':
    chain => 'OUTPUT',
    jump  => 'KUBE-FIREWALL',
    proto => 'all',
  }

  if $openshift::firewall_input_chain_ignore {
    firewallchain { 'INPUT:filter:IPv4':
      ignore => [
        '-i docker0',
        '-i tun0',
        '-j KUBE-FIREWALL',
        '-j KUBE-NODEPORT-NON-LOCAL',
        '-j KUBE-SERVICES',
        '-j OPENSHIFT-FIREWALL-ALLOW',
        'vxlan incoming'
      ],
      purge  => true,
    }
  }

  if $openshift::firewall_ignore_dynamic_chains {
    firewallchain { 'DOCKER:filter:IPv4':
      purge  => false,
    }

    firewallchain { 'DOCKER:nat:IPv4':
      purge  => false,
    }

    firewallchain { 'DOCKER-ISOLATION:filter:IPv4':
      purge => false,
    }

    firewallchain { 'FORWARD:filter:IPv4':
      purge => false,
    }

    # INPUT:filter:IPv4 ?

    firewallchain { 'KUBE-FIREWALL:filter:IPv4':
      purge => false,
    }

    firewallchain { 'KUBE-MARK-DROP:filter:IPv4':
      purge => false,
    }

    firewallchain { 'KUBE-MARK-DROP:nat:IPv4':
      purge => false,
    }

    firewallchain { 'KUBE-MARK-MASQ:filter:IPv4':
      purge => false,
    }

    firewallchain { 'KUBE-POSTROUTING:filter:IPv4':
      purge => false,
    }

    firewallchain { 'KUBE-POSTROUTING:nat:IPv4':
      purge => false,
    }
    
    firewallchain { 'KUBE-SERVICES:filter:IPv4':
      purge => false,
    }

    firewallchain { 'OPENSHIFT-FIREWALL-ALLOW:filter:IPv4':
      purge => false,
    }

    firewallchain { 'OS_FIREWALL_ALLOW:filter:IPv4':
      purge => false,
    }

    firewallchain { 'POSTROUTING:nat:IPv4':
      purge => false,
    }
  }

}
