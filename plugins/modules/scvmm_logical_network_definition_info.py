# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_network_definition_info
short_description: Query logical network definitions in SCVMM
description:
  - Retrieve information about logical network definitions (network sites) in SCVMM.
  - Can query all definitions, filter by name, or filter by logical network.
options:
  name:
    description:
      - Name of the logical network definition to query.
      - If not specified, returns all definitions.
    type: str
  logical_network:
    description:
      - Filter definitions by parent logical network name.
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
- name: Get all logical network definitions
  microsoft.scvmm.scvmm_logical_network_definition_info:
    vmm_server: scvmm.example.com
  register: all_definitions

- name: Get definitions for a specific logical network
  microsoft.scvmm.scvmm_logical_network_definition_info:
    logical_network: Management-LN
    vmm_server: scvmm.example.com
  register: mgmt_definitions

- name: Get a specific definition by name
  microsoft.scvmm.scvmm_logical_network_definition_info:
    name: Management-Site
    vmm_server: scvmm.example.com
  register: definition_info
'''

RETURN = r'''
logical_network_definitions:
  description: List of logical network definitions.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Definition ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Definition name.
      type: str
      returned: always
      sample: Management-Site
    logical_network:
      description: Name of the parent logical network.
      type: str
      returned: always
      sample: Management-LN
    subnet_vlans:
      description: List of subnet/VLAN pairs.
      type: list
      elements: dict
      returned: always
      contains:
        subnet:
          description: IP subnet in CIDR notation.
          type: str
          sample: "10.0.0.0/24"
        vlan_id:
          description: VLAN ID.
          type: int
          sample: 100
    host_groups:
      description: List of associated host group names.
      type: list
      elements: str
      returned: always
      sample: ["All Hosts"]
'''
