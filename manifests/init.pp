# Class: openshift
# ===========================
#
# Parameters
# ----------
#
#
# Variables
# ----------
#
#
# Examples
# --------
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
# Base class
class openshift(
  $build_defaults       = {},
  $build_overrides      = {},
  $ca_certfile          = '/path/to/ca.crt',
  $ca_keyfile           = '/path/to/ca.key',
  $children             = ['masters', 'nodes', 'etcd', 'lb'],
  $cluster_id           = 'default',
  $cluster_network      = '10.128.0.0/14',
  $console_ext_script   = '',
  $console_ext_style    = '',
  $dead_container_max   = 20,
  $debug_level          = 2,
  $default_subdomain    = "app.${::domain}",
  $dns_ip               = '172.30.0.1',
  $docker_options       = '--log-driver=journald',
  $docker_upgrade       = false,
  $docker_version       = '1.12.1',
  $enable_api_auditing  = true,
  $enable_cockpit       = true,
  $etcd_hosts           = [],
  $etcd_port            = 2379,
  $ingress_ip_network   = '172.46.0.0/16',
  $install_examples     = true,
  $iptables_sync_period = '5s',
  $labels               = {},
  $lb_domain            = "console.${::domain}",
  $logout_url           = "https://console.${::domain}",
  $manage_firewall      = false,
  $manage_origin_rpm    = false, # Requires $manage_repo be set to true
  $manage_repo          = false,
  $master_api_port      = 8443,
  $master_config_file   = '/etc/origin/master/master-config.yaml',
  $master_console_port  = 8443,
  $manage_kube_config   = false,
  $node_config_file     = '/etc/origin/node/node-config.yaml',
  $portal_net           = '172.30.0.0/16',
  $preserve_resolv_conf = 'present',
  $release,
  $reserved_system_cpu  = '500m',
  $reserved_system_mem  = '1Gi',
  $role                 = 'node', #For Ansible setup
  $sdn_plugin           = 'redhat/openshift-ovs-subnet', # Other option 'redhat/openshift-ovs-multitenant'
  $unschedulable_master = true,
  $version              = '1.5.1'
) {

 validate_re($role, '^(master|node)$', 'Only master and node role types are supported')

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
   enable => true,
   require => Package['NetworkManager'],
 }

 service { 'dnsmasq':
   ensure  => 'running',
   enable => true,
   require => Package['dnsmasq'],
 }

 ini_setting { "preserve resolv.conf":
   ensure  => $preserve_resolv_conf,
   notify  => Service['NetworkManager'],
   path    => '/etc/NetworkManager/NetworkManager.conf',
   require => Package['NetworkManager'],
   section => 'main',
   setting => 'dns',
   value   => 'none',
 }

 file { '/etc/resolv.conf':
   ensure => 'present',
   content => file('openshift/resolv.conf'),
   mode => '0775'
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
       "${dead_container_max}"
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
         'false'
       ],
     }
   }
 }

}
