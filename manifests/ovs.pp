# Class: openshift::ovs
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
class openshift::ovs inherits openshift {

  package { 'openvswitch':
    ensure  => $openshift::ovs_openvswitch_pkg_ensure,
    require => Yumrepo[$openshift::yum_repo_name],
  }

  package { $openshift::ovs_sdn_pkg:
    ensure  => $openshift::ovs_sdn_pkg_ensure,
    require => Yumrepo[$openshift::yum_repo_name],
  }

  service { 'ovs-vswitchd':
    ensure => 'running',
    notify => Service['ovsdb-server'],
  }

  service { 'ovsdb-server':
    ensure => 'running',
    notify => Service['openvswitch'],
  }

  service { 'openvswitch':
    ensure  => 'running',
    notify  => Service['docker'],
    require => Package['openvswitch'],
  }

}
