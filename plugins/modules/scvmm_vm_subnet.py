# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_subnet
short_description: Manage VM subnets in SCVMM
description:
  - Create, update, or remove VM subnets in System Center Virtual Machine Manager.
  - VM subnets define IP address ranges within a VM network.
options:
  name:
    description:
      - Name of the VM subnet.
    type: str
    required: true
  description:
    description:
      - Description of the VM subnet.
    type: str
  vm_network:
    description:
      - Name of the VM network to associate with this subnet.
      - Required when creating a new VM subnet.
    type: str
  subnet:
    description:
      - Subnet in CIDR notation (e.g. 10.0.0.0/24).
      - Required when creating a new VM subnet.
    type: str
  vlan_id:
    description:
      - VLAN ID for the subnet.
    type: int
    default: 0
  logical_network_definition:
    description:
      - Name of the logical network definition to associate.
      - Do not specify for VM networks using Hyper-V Network Virtualization.
    type: str
  state:
    description:
      - Desired state of the VM subnet.
    type: str
    choices: ['present', 'absent']
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a VM subnet
  microsoft.scvmm.scvmm_vm_subnet:
    name: MySubnet
    vm_network: MyVMNetwork
    subnet: "10.0.0.0/24"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a VM subnet
  microsoft.scvmm.scvmm_vm_subnet:
    name: MySubnet
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
vm_subnet:
  description: Details of the VM subnet.
  returned: when state is present
  type: dict
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
