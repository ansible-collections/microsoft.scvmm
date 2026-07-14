# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_group
short_description: Manage host groups in System Center Virtual Machine Manager
description:
  - Create, update, or remove host groups in SCVMM.
  - Host groups organize Hyper-V hosts into logical hierarchies.
  - Supports nested host group structures via the O(parent_host_group) parameter.
options:
  name:
    description:
      - Name of the host group.
    type: str
    required: true
  parent_host_group:
    description:
      - Name of the parent host group.
      - Defaults to V(All Hosts) if not specified.
    type: str
    default: All Hosts
  description:
    description:
      - Description of the host group.
    type: str
  state:
    description:
      - Desired state of the host group.
      - C(present) creates or updates a host group.
      - C(absent) removes a host group.
    type: str
    choices: ['present', 'absent']
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a host group under All Hosts
  microsoft.scvmm.scvmm_host_group:
    name: Production
    description: Production Hyper-V hosts
    state: present
    vmm_server: scvmm.example.com

- name: Create a nested host group
  microsoft.scvmm.scvmm_host_group:
    name: Tier1
    parent_host_group: Production
    description: Tier 1 production hosts
    state: present
    vmm_server: scvmm.example.com

- name: Update host group description
  microsoft.scvmm.scvmm_host_group:
    name: Production
    description: Updated production description
    state: present
    vmm_server: scvmm.example.com

- name: Remove a host group
  microsoft.scvmm.scvmm_host_group:
    name: OldGroup
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
host_group:
  description: Details of the host group.
  returned: when state is present and host group exists
  type: dict
  contains:
    id:
      description: Host group ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Host group name.
      type: str
      returned: always
      sample: Production
    description:
      description: Host group description.
      type: str
      returned: when available
      sample: Production Hyper-V hosts
    path:
      description: Full path of the host group in the hierarchy.
      type: str
      returned: always
      sample: "All Hosts\\Production"
    parent_host_group:
      description: Name of the parent host group.
      type: str
      returned: always
      sample: All Hosts
'''
