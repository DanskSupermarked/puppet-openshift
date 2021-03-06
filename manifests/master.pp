# Class: openshift::master
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
class openshift::master inherits openshift {

  if $openshift::master_manage_utilities_pkg {
    package { 'httpd-tools': # to generate a htpasswd file for hawkular
      ensure => 'installed',
    }

    package { 'java-1.8.0-openjdk-headless': # For keytool
      ensure => 'installed',
    }

    package { 'python-passlib':
      ensure => 'installed',
    }
  }

  if $openshift::manage_origin_rpm and !defined(Package['origin-master']) {
    package { 'origin-master':
      ensure  => $openshift::version,
      require => Yumrepo[$openshift::yum_repo_name],
    }
  }

  file { $openshift::master_config_file :
    ensure  => 'file',
    replace => false,
  }

  file { $openshift::master_sysconfig_file :
    ensure  => 'file',
    content => template('openshift/sysconfig_openshift_master.erb'),
  }

  if $openshift::master_ha_cluster {
    file { "${openshift::master_sysconfig_file}-api" :
      ensure  => 'file',
      content => template('openshift/sysconfig_openshift_master_api.erb'),
    }

    file { "${openshift::master_sysconfig_file}-controllers" :
      ensure  => 'file',
      content => template('openshift/sysconfig_openshift_master_controllers.erb'),
    }

  }

  if $openshift::manage_kube_config {
    if $openshift::master_default_node_selector != '' {
      yaml_setting { 'projectConfig_default_node_selector' :
        target => $openshift::master_config_file,
        key    => 'projectConfig/defaultNodeSelector',
        type   => 'string',
        value  => $openshift::master_default_node_selector
      }
    }
  }

  yaml_setting { 'master_enable_api_auditing' :
    target => $openshift::master_config_file,
    key    => 'auditConfig/enabled',
    type   => 'boolean', # https://github.com/reidmv/puppet-module-yamlfile/issues/12
    value  => $openshift::master_enable_api_auditing
  }

  if $openshift::master_manage_service {
    if !$openshift::master_ha_cluster {
      service { $openshift::master_service_name:
        ensure    => 'running',
        subscribe => File[$openshift::master_sysconfig_file],
      }

      Yaml_setting <| target == $openshift::master_config_file |> {
        notify => Service[$openshift::master_service_name],
      }
    } else {
      service { "${openshift::master_service_name}-api" :
        ensure    => 'running',
        subscribe => File["${openshift::master_sysconfig_file}-api"],
      }

      service { "${openshift::master_service_name}-controllers" :
        ensure    => 'running',
        subscribe => File["${openshift::master_sysconfig_file}-controllers"],
      }

      Yaml_setting <| target == $openshift::master_config_file |> {
        notify => [
          Service["${openshift::master_service_name}-api"],
          Service["${openshift::master_service_name}-controllers"]
        ],
      }
    }

  }

}
