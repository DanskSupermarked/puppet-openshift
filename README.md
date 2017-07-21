# puppet-openshift
Work in progress -> need to call and manage Ansible.

This module is meant to go a step further than the Ansible script installing OpenShift.

The Ansible setup alone will not allow you to integrate an OpenShift cluster into an existing infrastructure managed with Puppet. There is also some shortcoming when it comes to managing lifecycle/state of an OpenShift cluster with only the Ansible playbook provided by Red Hat.

## Key Features
- Manage IP Tables to permit dynamic container rules while securing cluster.
- Manage network/DNS.
- Tune Kubernetes.
