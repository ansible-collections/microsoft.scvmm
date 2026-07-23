# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_network_adapter
short_description: Manage virtual network adapters on VMs in SCVMM
description:
  - Add or remove virtual network adapters on virtual machines in SCVMM.
  - Uses New-SCVirtualNetworkAdapter to add a NIC.
  - Uses Remove-SCVirtualNetworkAdapter to remove the last NIC.
options:
  vm_name:
    description:
      - Name of the virtual machine.
    type: str
    required: true
  vm_network:
    description:
      - VM network to connect the adapter to.
      - If not specified, adapter is created with no connection.
    type: str
  mac_address_type:
    description:
      - MAC address assignment type.
    type: str
    choices: ['Static', 'Dynamic']
  mac_address:
    description:
      - Static MAC address to assign.
    type: str
  ipv4_address_type:
    description:
      - IPv4 address assignment type.
    type: str
    choices: ['Static', 'Dynamic']
  synthetic:
    description:
      - Create a synthetic (paravirtualized) adapter.
    type: bool
    default: true
  state:
    description:
      - C(present) adds a new network adapter.
      - C(absent) removes the last network adapter.
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
- name: Add a network adapter to a VM
  microsoft.scvmm.scvmm_network_adapter:
    vm_name: MyVM
    vm_network: MyVMNetwork
    state: present
    vmm_server: scvmm.example.com

- name: Remove last adapter from a VM
  microsoft.scvmm.scvmm_network_adapter:
    vm_name: MyVM
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
network_adapter:
  description: Details of the network adapter.
  returned: when state is present
  type: dict
  contains:
    id:
      description: Adapter ID.
      type: str
    name:
      description: Adapter name.
      type: str
    vm_name:
      description: VM name.
      type: str
    vm_network:
      description: Connected VM network name.
      type: str
    mac_address:
      description: MAC address.
      type: str
    mac_address_type:
      description: MAC address type (Static/Dynamic).
      type: str
    ipv4_addresses:
      description: IPv4 addresses assigned.
      type: list
      elements: str
    is_synthetic:
      description: Whether the adapter is synthetic.
      type: bool
'''
