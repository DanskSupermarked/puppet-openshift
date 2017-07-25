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

  file { $openshift::node_config_file:
    ensure  => 'file',
    replace => false,
  }

  file { $openshift::node_sysconfig_file :
    ensure  => 'file',
    content => template('openshift/sysconfig_openshift_node.erb'),
  }

  if $openshift::manage_kube_config {
    yaml_setting { "kubeletArguments_eviction_${openshift::node_eviction_type}" :
      target => $openshift::node_config_file,
      key    => "kubeletArguments/${openshift::node_eviction_type}",
      type   => 'array',
      value  => [
        'memory.available<500Mi'
      ],
    }

    # openshift_node_kubelet_args={'pods-per-core': ['10'], 'max-pods': ['250'], 'image-gc-high-threshold': ['90'], 'image-gc-low-threshold': ['80']}
    yaml_setting { 'kubeletArguments_max_pods' :
      target => $openshift::node_config_file,
      key    => 'kubeletArguments/max-pods',
      type   => 'array',
      value  => [
        "'${openshift::pod_max}'" # Kube expects an array of strings
      ],
    }

    yaml_setting { 'kubeletArguments_system_reserved' :
      target => $openshift::node_config_file,
      key    => 'kubeletArguments/system-reserved',
      type   => 'array',
      value  => [
        "cpu=${openshift::reserved_system_cpu},memory=${openshift::reserved_system_mem}"
      ],
    }

    yaml_setting { 'kubeletArguments_dead_container_max' :
      target => $openshift::node_config_file,
      key    => 'kubeletArguments/maximum-dead-containers',
      type   => 'array',
      value  => [
        "'${openshift::dead_container_max}'"
      ],
    }

    yaml_setting { 'kubeletArguments_image_gc_low_threshold' :
      target => $openshift::node_config_file,
      key    => 'kubeletArguments/image-gc-low-threshold',
      type   => 'array',
      value  => [
        '60'
      ],
    }

    yaml_setting { 'kubeletArguments_image_gc_high_threshold' :
      target => $openshift::node_config_file,
      key    => 'kubeletArguments/image-gc-high-threshold',
      type   => 'array',
      value  => [
        '80'
      ],
    }

    if versioncmp($openshift::docker_version, '1.9.0') >= 0 { # Starting from Docker 1.9, parallel image pulls are recommanded for speed.
      yaml_setting { 'kubeletArguments_serialize_image_pulls' :
        target => $openshift::node_config_file,
        key    => 'kubeletArguments/system-serialize-image-pulls',
        type   => 'array',
        value  => [
          false
        ],
      }
    }
  }

  if $openshift::node_service_name != '' and $openshift::node_manage_service {
    service { $openshift::node_service_name:
      ensure    => 'running',
      subscribe => File[$openshift::node_sysconfig_file],
    }

    Yaml_setting <| target == $openshift::config_file |> {
      notify => Service[$openshift::node_service_name],
    }
  }

}
