# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_network_adapter_info
short_description: Query virtual network adapters on VMs in SCVMM
description:
  - Retrieve information about virtual network adapters attached to a VM.
options:
  vm_name:
    description:
      - Name of the virtual machine to query adapters for.
    type: str
    required: true
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get network adapters for a VM
  microsoft.scvmm.scvmm_network_adapter_info:
    vm_name: MyVM
    vmm_server: scvmm.example.com
  register: nic_info
'''

RETURN = r'''
network_adapters:
  description: List of network adapters.
  returned: always
  type: list
  elements: dict
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
      description: MAC address type.
      type: str
    ipv4_addresses:
      description: IPv4 addresses.
      type: list
      elements: str
    is_synthetic:
      description: Whether the adapter is synthetic.
      type: bool
'''
