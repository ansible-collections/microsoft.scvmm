# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_cluster
short_description: Manage Hyper-V failover clusters in System Center Virtual Machine Manager
description:
  - Create, update, or remove Hyper-V failover clusters in SCVMM.
  - Can install a new failover cluster from managed hosts.
  - Can update cluster properties such as description and cluster reserve.
  - Can uninstall a failover cluster.
options:
  name:
    description:
      - Name of the failover cluster.
    type: str
    required: true
  state:
    description:
      - Desired state of the cluster.
      - C(present) creates or updates the cluster.
      - C(absent) uninstalls the cluster.
    type: str
    choices: [present, absent]
    default: present
  description:
    description:
      - Description for the cluster.
    type: str
  cluster_reserve:
    description:
      - Number of host failures the cluster can sustain.
    type: int
  nodes:
    description:
      - List of host FQDNs to include as cluster nodes.
      - Required when creating a new cluster.
    type: list
    elements: str
  cluster_ip_address:
    description:
      - IP address for the cluster.
      - Required when creating a new cluster.
    type: str
  credential_username:
    description:
      - Username for cluster operations.
      - Required when creating a new cluster.
    type: str
  credential_password:
    description:
      - Password for cluster operations.
      - Required when creating a new cluster.
    type: str
  skip_validation:
    description:
      - Skip cluster validation during creation.
    type: bool
    default: false
  cleanup_disks:
    description:
      - Clean up disks when removing the cluster.
    type: bool
    default: false
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a failover cluster
  microsoft.scvmm.scvmm_host_cluster:
    name: MyCluster
    state: present
    nodes:
      - host01.example.com
      - host02.example.com
    cluster_ip_address: 10.0.0.100
    credential_username: admin@example.com
    credential_password: secret
    description: Production cluster
    vmm_server: scvmm.example.com

- name: Update cluster description
  microsoft.scvmm.scvmm_host_cluster:
    name: MyCluster
    description: Updated production cluster
    vmm_server: scvmm.example.com

- name: Remove a failover cluster
  microsoft.scvmm.scvmm_host_cluster:
    name: MyCluster
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
cluster:
  description: The cluster details.
  returned: when state is present
  type: dict
  contains:
    id:
      description: Cluster ID in SCVMM.
      type: str
      returned: always
    name:
      description: Cluster name.
      type: str
      returned: always
    description:
      description: Cluster description.
      type: str
      returned: always
    cluster_reserve:
      description: Number of host failures the cluster can sustain.
      type: int
      returned: always
    node_count:
      description: Number of nodes in the cluster.
      type: int
      returned: always
    nodes:
      description: List of node names in the cluster.
      type: list
      elements: str
      returned: always
    host_group:
      description: Name of the host group containing the cluster.
      type: str
      returned: always
'''
