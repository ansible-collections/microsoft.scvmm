# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_cluster_info
short_description: Query host cluster information in System Center Virtual Machine Manager
description:
  - Retrieve information about Hyper-V host clusters managed by SCVMM.
  - Can query all clusters or filter by name.
options:
  name:
    description:
      - Name of the host cluster to query.
      - If not specified, returns all clusters.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all host clusters
  microsoft.scvmm.scvmm_host_cluster_info:
    vmm_server: scvmm.example.com
  register: all_clusters

- name: Get a specific cluster
  microsoft.scvmm.scvmm_host_cluster_info:
    name: HyperV-Cluster01
    vmm_server: scvmm.example.com
  register: cluster_info
'''

RETURN = r'''
host_clusters:
  description: List of host clusters.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Cluster ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Cluster name.
      type: str
      returned: always
      sample: HyperV-Cluster01
    description:
      description: Cluster description.
      type: str
      returned: when available
    host_group:
      description: Name of the host group containing this cluster.
      type: str
      returned: always
      sample: Production
    status:
      description: Overall cluster status.
      type: str
      returned: always
      sample: Responding
    node_count:
      description: Number of nodes in the cluster.
      type: int
      returned: always
      sample: 4
    shared_volumes:
      description: Names of cluster shared volumes.
      type: list
      elements: str
      returned: always
      sample: ["CSV1", "CSV2"]
'''
