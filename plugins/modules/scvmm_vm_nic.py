# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_nic
short_description: Configure virtual network adapter settings on VMs in SCVMM
description:
  - Configure settings on an existing virtual network adapter.
  - Uses Set-SCVirtualNetworkAdapter to update NIC properties.
  - The adapter must already exist on the VM (use M(microsoft.scvmm.scvmm_network_adapter) to add or remove adapters).
  - Identifies the adapter by V(vm_network).
options:
  vm_name:
    description:
      - Name of the virtual machine.
    type: str
    required: true
  vm_network:
    description:
      - VM network the adapter is connected to.
      - Used to identify which adapter to configure.
    type: str
    required: true
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
  vlan_enabled:
    description:
      - Whether VLAN tagging is enabled on the adapter.
    type: bool
  vlan_id:
    description:
      - VLAN ID to tag traffic with.
    type: int
  port_classification:
    description:
      - Name of the port classification to assign.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Set MAC address type to Static
  microsoft.scvmm.scvmm_vm_nic:
    vm_name: MyVM
    vm_network: MyVMNetwork
    mac_address_type: Static
    mac_address: "00:1A:2B:3C:4D:5E"
    vmm_server: scvmm.example.com

- name: Enable VLAN tagging
  microsoft.scvmm.scvmm_vm_nic:
    vm_name: MyVM
    vm_network: MyVMNetwork
    vlan_enabled: true
    vlan_id: 100
    vmm_server: scvmm.example.com

- name: Set port classification
  microsoft.scvmm.scvmm_vm_nic:
    vm_name: MyVM
    vm_network: MyVMNetwork
    port_classification: "High bandwidth"
    vmm_server: scvmm.example.com
'''

RETURN = r'''
vm_nic:
  description: Current adapter settings after changes.
  returned: always
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
    vlan_enabled:
      description: Whether VLAN tagging is enabled.
      type: bool
    vlan_id:
      description: VLAN ID.
      type: int
    port_classification:
      description: Port classification name.
      type: str
    ipv4_addresses:
      description: IPv4 addresses assigned.
      type: list
      elements: str
    is_synthetic:
      description: Whether the adapter is synthetic.
      type: bool
'''
