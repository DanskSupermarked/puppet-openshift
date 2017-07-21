# Class: openshift
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
class openshift(
  Hash $build_defaults,
  Hash $build_overrides,
  $ca_certfile,
  String $ca_keyfile,
  Array[String] $children,
  String $cluster_id,
  String $cluster_network,
  Optional[String] $console_ext_script,
  Optional[String] $console_ext_style,
  Integer $dead_container_max,
  Integer[0, 5] $debug_level,
  String $default_subdomain,
  String $dns_ip,
  String $dnsmasq_conf_file,
  Array[String] $dnsmasq_servers,
  Optional[String] $docker_options, # Can also be set via Docker module
  Boolean $docker_upgrade,
  String $docker_version,
  Boolean $enable_cockpit,
  Optional[Array] $etcd_hosts,
  Integer $etcd_port,
  Boolean $firewall_ignore_dynamic_chains,
  Boolean $firewall_input_chain_ignore,
  String $ingress_ip_network,
  Boolean $install_examples,
  String $iptables_sync_period,
  Hash $labels,
  String $lb_domain,
  String $logout_url,
  Boolean $manage_firewall,
  Boolean $manage_kube_config,
  Boolean $manage_origin_rpm, # Requires $manage_repo be set to true
  Boolean $manage_repo,
  Integer $master_api_port,
  String $master_config_file,
  Integer $master_console_port,
  Optional[String] $master_default_node_selector,
  Boolean $master_enable_api_auditing,
  Integer[0, 8] $master_log_level,
  Boolean $master_manage_service,
  Boolean $master_manage_utilities_pkg,
  String $master_service_name,
  String $master_sysconfig_file,
  String $node_config_file,
  Enum['hard', 'soft'] $node_eviction_type,
  Integer[0, 8] $node_log_level,
  Boolean $node_manage_service,
  String $node_name,
  Integer $node_pod_max,
  String $node_service_name,
  String $portal_net,
  Enum['absent', 'present'] $preserve_resolv_conf,
  String $release,
  String $reserved_system_cpu,
  String $reserved_system_mem,
  String $resolv_search_domains,
  Enum['master', 'node'] $role, #For Ansible setup
  String $sdn_plugin, # Other option 'redhat/openshift-ovs-multitenant'
  Boolean $unschedulable_master,
  String $version
) {

  # To feed Ansible setup script about cluster members:
  # Use PuppetDB for master, etcd, lb and node lookup? Format:
  # $nodes = {$::fqdn => "openshift_node_labels=\"{'region': 'primary', 'zone': 'default', 'virtual': '${::is_virtual}'}\""}
  # $lbs = { "lb.${::domain}" => 'containerized=false'}

  if $manage_repo and !defined(Yumrepo['centos-openshift-origin']) {
    yumrepo { 'centos-openshift-origin':
      baseurl  => "http://mirror.centos.org/centos/${::operatingsystemmajrelease}/paas/${::architecture}/openshift-origin/",
      descr    => 'CentOS OpenShift Origin',
      gpgcheck => true,
      gpgkey   => "http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-${::operatingsystemmajrelease}",
    }
  }

  package { 'NetworkManager':
    ensure => 'installed',
  }

  package { 'dnsmasq':
    ensure => 'installed',
  }

  service { 'NetworkManager':
    ensure  => 'running',
    enable  => true,
    require => Package['NetworkManager'],
  }

  service { 'dnsmasq':
    ensure  => 'running',
    enable  => true,
    require => Package['dnsmasq'],
  }

  file { $dnsmasq_conf_file :
    ensure  => 'present',
    content => template('openshift/dnsmasq.conf.erb'),
    mode    => '0775',
    notify  => Service['dnsmasq'],
  }

  ini_setting { 'preserve_resolv.conf':
    ensure  => $preserve_resolv_conf,
    notify  => Service['NetworkManager'],
    path    => '/etc/NetworkManager/NetworkManager.conf',
    require => Package['NetworkManager'],
    section => 'main',
    setting => 'dns',
    value   => 'none',
  }

  file { '/etc/resolv.conf':
    ensure  => 'present',
    content => template('openshift/resolv.conf.erb'),
    mode    => '0775',
  }

  # Should add USE_PEERDNS and NM_CONTROLLED to the net interface used

  if $manage_kube_config {
    if $role == 'node' {
      $config_file = $node_config_file
    } else {
      $config_file = $master_config_file
    }

    yaml_setting { 'kubeletArguments_system_reserved' :
      target => $config_file,
      key    => 'kubeletArguments/system-reserved',
      type   => 'array',
      value  => [
        "cpu=${reserved_system_cpu},memory=${reserved_system_mem}"
      ],
    }

    yaml_setting { 'kubeletArguments_dead_container_max' :
      target => $config_file,
      key    => 'kubeletArguments/maximum-dead-containers',
      type   => 'array',
      value  => [
        "'${dead_container_max}'"
      ],
    }

    yaml_setting { 'kubeletArguments_image_gc_low_threshold' :
      target => $config_file,
      key    => 'kubeletArguments/image-gc-low-threshold',
      type   => 'array',
      value  => [
        '60'
      ],
    }

    yaml_setting { 'kubeletArguments_image_gc_high_threshold' :
      target => $config_file,
      key    => 'kubeletArguments/image-gc-high-threshold',
      type   => 'array',
      value  => [
        '80'
      ],
    }

    if versioncmp($docker_version, '1.9.0') >= 0 { # Starting from Docker 1.9, parallel image pulls are recommanded for speed.
      yaml_setting { 'kubeletArguments_serialize_image_pulls' :
        target => $config_file,
        key    => 'kubeletArguments/system-serialize-image-pulls',
        type   => 'array',
        value  => [
          false
        ],
      }
    }
  }

  if $manage_firewall {
    contain openshift::firewall
  }

}
