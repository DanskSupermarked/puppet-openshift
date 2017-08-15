# Manage OpenShift 3 with Puppet
[![Build Status](https://travis-ci.org/DanskSupermarked/puppet-openshift.svg?branch=master)](https://travis-ci.org/DanskSupermarked/puppet-openshift)

## Work in progress

This module is meant to go a step further than the Ansible script installing OpenShift.

The Ansible setup alone will not allow you to integrate an OpenShift cluster into an existing infrastructure managed with Puppet. There is also some shortcoming when it comes to managing lifecycle/state of an OpenShift cluster with only the Ansible playbook provided by Red Hat.

## Key Features
- Manage IP Tables to permit dynamic container rules while securing cluster.
- Manage network/DNS.
- Tune Kubernetes.
- Prepares a node (not a master) to join an existing cluster.

## TODO
- Add option to call oadm to mark a node as unschedulable and evacuate Pods before restarting origin service.
