# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_subnet_info
short_description: Query VM subnets in SCVMM
description:
  - Retrieve information about VM subnets in SCVMM.
  - Can filter by name or VM network.
options:
  name:
    description:
      - Name of the VM subnet to query.
    type: str
  vm_network:
    description:
      - Filter subnets by VM network name.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all VM subnets
  microsoft.scvmm.scvmm_vm_subnet_info:
    vmm_server: scvmm.example.com

- name: Get VM subnets for a specific VM network
  microsoft.scvmm.scvmm_vm_subnet_info:
    vm_network: MyVMNetwork
    vmm_server: scvmm.example.com
'''

RETURN = r'''
vm_subnets:
  description: List of VM subnets.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Subnet ID.
      type: str
    name:
      description: Subnet name.
      type: str
    description:
      description: Subnet description.
      type: str
    vm_network:
      description: Associated VM network name.
      type: str
    subnet_vlans:
      description: List of subnet/VLAN associations.
      type: list
      elements: dict
      contains:
        subnet:
          description: Subnet in CIDR notation.
          type: str
        vlan_id:
          description: VLAN ID.
          type: int
    logical_network_definition:
      description: Associated logical network definition name.
      type: str
'''
