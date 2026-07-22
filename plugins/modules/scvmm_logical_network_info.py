# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_network_info
short_description: Query logical networks in System Center Virtual Machine Manager
description:
  - Retrieve information about logical networks in SCVMM.
  - Can query all logical networks or filter by name.
options:
  name:
    description:
      - Name of the logical network to query.
      - If not specified, returns all logical networks.
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
- name: Get all logical networks
  microsoft.scvmm.scvmm_logical_network_info:
    vmm_server: scvmm.example.com
  register: all_networks

- name: Get a specific logical network
  microsoft.scvmm.scvmm_logical_network_info:
    name: Management-LN
    vmm_server: scvmm.example.com
  register: network_info

- name: Display logical network details
  ansible.builtin.debug:
    msg: "Network {{ item.name }} virtualization={{ item.network_virtualization_enabled }}"
  loop: "{{ all_networks.logical_networks }}"
'''

RETURN = r'''
logical_networks:
  description: List of logical networks.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Logical network ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Logical network name.
      type: str
      returned: always
      sample: Management-LN
    description:
      description: Logical network description.
      type: str
      returned: when available
      sample: Management logical network
    network_virtualization_enabled:
      description: Whether network virtualization is enabled.
      type: bool
      returned: always
      sample: false
    use_gre:
      description: Whether GRE is enabled.
      type: bool
      returned: always
      sample: false
    is_pvlan:
      description: Whether PVLAN is enabled.
      type: bool
      returned: always
      sample: false
    definition_isolation:
      description: Whether logical network definition isolation is enabled.
      type: bool
      returned: always
      sample: false
    allow_dynamic_vlan_on_vnic:
      description: Whether dynamic VLAN on vNIC is allowed.
      type: bool
      returned: always
      sample: false
'''
