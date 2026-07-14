# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_group_info
short_description: Query host groups in System Center Virtual Machine Manager
description:
  - Retrieve information about host groups in SCVMM.
  - Can query all host groups or filter by name.
  - Returns host group hierarchy including parent, children, hosts, and clouds.
options:
  name:
    description:
      - Name of the host group to query.
      - If not specified, returns all host groups.
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
- name: Get all host groups
  microsoft.scvmm.scvmm_host_group_info:
    vmm_server: scvmm.example.com
  register: all_groups

- name: Get a specific host group
  microsoft.scvmm.scvmm_host_group_info:
    name: Production
    vmm_server: scvmm.example.com
  register: group_info

- name: Display host group hierarchy
  ansible.builtin.debug:
    msg: "{{ item.name }} ({{ item.path }}) - {{ item.hosts | length }} hosts"
  loop: "{{ all_groups.host_groups }}"
'''

RETURN = r'''
host_groups:
  description: List of host groups.
  returned: always
  type: list
  elements: dict
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
      sample: "All Hosts"
    description:
      description: Host group description.
      type: str
      returned: always
    path:
      description: Full path of the host group in the hierarchy.
      type: str
      returned: always
      sample: "All Hosts\\Production"
    parent_host_group:
      description: Name of the parent host group.
      type: str
      returned: when available
    child_host_groups:
      description: Names of child host groups.
      type: list
      elements: str
      returned: always
    hosts:
      description: FQDNs of hosts in this group.
      type: list
      elements: str
      returned: always
    clouds:
      description: Names of clouds associated with this group.
      type: list
      elements: str
      returned: always
'''
