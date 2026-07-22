# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_network_definition
short_description: Manage logical network definitions (network sites) in SCVMM
description:
  - Create, update, or remove logical network definitions in System Center Virtual Machine Manager.
  - A logical network definition assigns IP subnets, VLANs, and host groups to a logical network.
  - Uses New-SCLogicalNetworkDefinition to create new definitions.
  - Uses Set-SCLogicalNetworkDefinition to update existing definitions.
  - Uses Remove-SCLogicalNetworkDefinition to delete definitions.
options:
  name:
    description:
      - Name of the logical network definition.
    type: str
    required: true
  logical_network:
    description:
      - Name of the parent logical network.
      - Required when I(state=present).
    type: str
  subnet_vlans:
    description:
      - List of subnet/VLAN pairs for this definition.
      - Required when creating a new definition.
    type: list
    elements: dict
    suboptions:
      subnet:
        description:
          - IP subnet in CIDR notation (e.g., C(10.0.0.0/24)).
        type: str
        required: true
      vlan_id:
        description:
          - VLAN ID for the subnet.
          - Set to C(0) for no VLAN tagging.
        type: int
        default: 0
  host_groups:
    description:
      - List of host group names to associate with this definition.
      - Required when creating a new definition.
    type: list
    elements: str
  state:
    description:
      - Desired state of the logical network definition.
      - C(present) creates or updates a definition.
      - C(absent) removes a definition.
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
- name: Create a logical network definition
  microsoft.scvmm.scvmm_logical_network_definition:
    name: Management-Site
    logical_network: Management-LN
    subnet_vlans:
      - subnet: "10.0.0.0/24"
        vlan_id: 100
    host_groups:
      - All Hosts
    state: present
    vmm_server: scvmm.example.com

- name: Create definition with multiple subnets
  microsoft.scvmm.scvmm_logical_network_definition:
    name: MultiSite
    logical_network: Corp-LN
    subnet_vlans:
      - subnet: "10.0.1.0/24"
        vlan_id: 101
      - subnet: "10.0.2.0/24"
        vlan_id: 102
    host_groups:
      - All Hosts
    state: present
    vmm_server: scvmm.example.com

- name: Remove a logical network definition
  microsoft.scvmm.scvmm_logical_network_definition:
    name: Management-Site
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
logical_network_definition:
  description: Details of the logical network definition.
  returned: when state is present and definition exists
  type: dict
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
