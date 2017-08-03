# Class: openshift::etcd
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
class openshift::etcd inherits openshift {

  if $openshift::etcd_manage_rpm {
    package { 'etcd' :
      ensure => 'installed',
    }
  }

  if $openshift::etcd_manage_service {
    service { 'etcd' :
      ensure => 'running',
    }
  }

}
