# Class: openshift::node
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
class openshift::node inherits openshift {

  if $openshift::manage_origin_rpm and !defined(Package['origin-node']) {
    package { 'origin-node':
      ensure  => $openshift::version,
      require => Yumrepo['centos-openshift-origin'],
    }
  }

  if $openshift::manage_kube_config {
    file { $node_config:
      ensure => 'file',
    }

    yaml_setting { "kubeletArguments_eviction_${openshift::node_eviction_type}" :
      target => $openshift::config_file,
      key    => "kubeletArguments/${openshift::node_eviction_type}",
      type   => 'array',
      value  => [
        'memory.available<500Mi'
      ],
  }

    # openshift_node_kubelet_args={'pods-per-core': ['10'], 'max-pods': ['250'], 'image-gc-high-threshold': ['90'], 'image-gc-low-threshold': ['80']}
    yaml_setting { 'kubeletArguments_max_pods' :
      target => $openshift::config_file,
      key    => 'kubeletArguments/max-pods',
      type   => 'array',
      value  => [
        "${openshift::pod_max}" # Kube expects an array of strings
      ],
    }
  }

 if $openshift::node_service_name != '' and $openshift::node_manage_service {
   service { $openshift::node_service_name:
     ensure => 'running',
   }

   Yaml_setting <| target == $openshift::config_file |> {
     notify => Service[$openshift::node_service_name],
   }
 }

}
