# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_template_nic
version_added: "1.3.0"
short_description: Configure virtual network adapter settings on VM templates in SCVMM
description:
  - Configure settings on the network adapter of an existing VM template.
  - Uses Set-SCVirtualNetworkAdapter to bind the template's adapter to a VM network and subnet
    and to update adapter properties.
  - Operates on the template's first network adapter.
  - This is commonly used to bind the adapter of a cloned template (see M(microsoft.scvmm.scvmm_template))
    to the target VM network before deploying a VM from it with M(microsoft.scvmm.scvmm_vm).
options:
  template_name:
    description:
      - Name of the VM template whose network adapter should be configured.
    type: str
    required: true
  vm_network:
    description:
      - VM network to bind the template adapter to.
    type: str
    required: true
  vm_subnet:
    description:
      - Name of the VM subnet within O(vm_network) to bind the adapter to.
      - Typically required when moving the adapter across VM networks on a logical-switch fabric.
      - When omitted, the first subnet of O(vm_network) is used when the adapter is (re)bound.
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
- name: Bind a template adapter to a VM network and subnet
  microsoft.scvmm.scvmm_template_nic:
    template_name: Windows2022Template
    vm_network: Corporate-Prod
    vm_subnet: Corporate-Prod-10.1.0.0_24
    vmm_server: scvmm.example.com

- name: Bind a cloned template adapter before deploying a VM from it
  microsoft.scvmm.scvmm_template:
    name: "tmp-clone-12345"
    source_template: Windows2022Template
    state: present

- name: Configure the cloned template's adapter
  microsoft.scvmm.scvmm_template_nic:
    template_name: "tmp-clone-12345"
    vm_network: Corporate-Prod
    vm_subnet: Corporate-Prod-10.1.0.0_24
    vmm_server: scvmm.example.com

- name: Set a static MAC and VLAN on a template adapter
  microsoft.scvmm.scvmm_template_nic:
    template_name: Windows2022Template
    vm_network: Corporate-Prod
    vm_subnet: Corporate-Prod-10.1.0.0_24
    mac_address_type: Static
    mac_address: "00:1A:2B:3C:4D:5E"
    vlan_enabled: true
    vlan_id: 100
    vmm_server: scvmm.example.com
'''

RETURN = r'''
template_nic:
  description: Current template adapter settings after changes.
  returned: always
  type: dict
  contains:
    id:
      description: Adapter ID.
      type: str
    name:
      description: Adapter name.
      type: str
    template_name:
      description: VM template name.
      type: str
    vm_network:
      description: Connected VM network name.
      type: str
    vm_subnet:
      description: Connected VM subnet name.
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
    is_synthetic:
      description: Whether the adapter is synthetic.
      type: bool
'''
