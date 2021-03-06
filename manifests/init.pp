# openshift
#
# @param docker_options [Optional[String]] Can also be set via Docker module.
# @param manage_origin_rpm [Boolean] Requires $manage_repo be set to true.
# @param node_labels [Optional[Array[String]]] An array of strings in the "key=value" format.
#
# Authors
# -------
# Benjamin Merot <benjamin.merot@dsg.dk>
#
# Copyright
# ---------
# Copyright 2017 Dansk Supermarked.
#
class openshift(
  Optional[Hash] $build_defaults,
  Optional[Hash] $build_overrides,
  Optional[String] $ca_certfile,
  Optional[String] $ca_keyfile,
  Array[String] $children,
  String $cluster_domain,
  String $cluster_id,
  Optional[String] $cluster_name,
  String $cluster_network,
  Optional[String] $console_ext_script,
  Optional[String] $console_ext_style,
  Optional[String] $dead_container_max,
  Integer[0, 5] $debug_level,
  String $default_subdomain,
  String $dns_ip,
  String $dnsmasq_conf_file,
  Array[String] $dnsmasq_servers,
  Optional[String] $docker_options,
  Boolean $docker_upgrade,
  String $docker_version,
  Boolean $enable_cockpit,
  Boolean $etcd_manage_rpm,
  Boolean $etcd_manage_service,
  Integer $etcd_port,
  Boolean $firewall_ignore_dynamic_chains,
  Boolean $firewall_input_chain_ignore,
  String $ingress_ip_network,
  Boolean $install_examples,
  String $iptables_sync_period,
  Optional[String] $lb_domain,
  String $logout_url,
  Boolean $manage_firewall,
  Boolean $manage_kube_config,
  Boolean $manage_origin_rpm,
  Boolean $manage_ovs,
  Boolean $manage_repo,
  Integer $master_api_port,
  String $master_config_file,
  Integer $master_console_port,
  Integer $master_controller_port,
  Optional[String] $master_default_node_selector,
  Boolean $master_enable_api_auditing,
  Boolean $master_ha_cluster,
  Integer[0, 8] $master_log_level,
  Boolean $master_manage_service,
  Boolean $master_manage_utilities_pkg,
  String $master_service_name,
  String $master_sysconfig_file,
  String $master_url_internal,
  String $node_config_file,
  Optional[Array[String]] $node_eviction_hard,
  Optional[Array[String]] $node_eviction_soft,
  Optional[Array[String]] $node_eviction_soft_grace_period,
  Optional[String] $node_fqdn_internal,
  Optional[Array[String]] $node_labels,
  Integer[0, 8] $node_log_level,
  Boolean $node_manage_master_kube_config,
  Boolean $node_manage_service,
  Optional[String] $node_master_kube_config_file,
  String $node_name,
  Optional[String] $node_pod_max,
  String $node_service_name,
  String $node_sysconfig_file,
  String $ovs_openvswitch_pkg_ensure,
  String $ovs_sdn_pkg,
  String $ovs_sdn_pkg_ensure,
  String $portal_net,
  Enum['absent', 'present'] $preserve_resolv_conf,
  String $release,
  String $reserved_system_cpu,
  String $reserved_system_mem,
  String $resolv_nameserver,
  String $resolv_search_domains,
  Enum['etcd', 'master', 'node'] $role,
  Enum['redhat/openshift-ovs-multitenant', 'redhat/openshift-ovs-subnet'] $sdn_plugin,
  Boolean $unschedulable_master,
  String $version,
  String $yum_baseurl,
  Boolean $yum_gpgcheck,
  String $yum_gpgkey,
  String $yum_repo_description,
  String $yum_repo_name
) {

  # To feed Ansible setup script about cluster members:
  # Use PuppetDB for master, etcd, lb and node lookup? Format:
  # $nodes = {$::fqdn => "openshift_node_labels=\"{'region': 'primary', 'zone': 'default', 'virtual': '${::is_virtual}'}\""}
  # $lbs = { "lb.${::domain}" => 'containerized=false'}

  if $manage_repo and !defined(Yumrepo[$yum_repo_name]) {
    yumrepo { $yum_repo_name :
      baseurl  => $yum_baseurl,
      descr    => $yum_repo_description,
      gpgcheck => $yum_gpgcheck,
      gpgkey   => $yum_gpgkey,
    }
  }

  package { 'NetworkManager':
    ensure => 'installed',
  }

  service { 'NetworkManager':
    ensure  => 'running',
    enable  => true,
    require => Package['NetworkManager'],
  }

  package { 'dnsmasq':
    ensure => 'installed',
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

  if $role == 'etcd' {
    contain openshift::etcd
  } elsif $role == 'master' {
    contain openshift::master
    contain openshift::node
  } else {
    contain openshift::node
  }

  if $manage_firewall {
    contain openshift::firewall
  }

  if $manage_ovs {
    contain openshift::ovs
  }

}
