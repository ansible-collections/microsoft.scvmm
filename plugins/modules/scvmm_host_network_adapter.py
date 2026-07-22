# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_network_adapter
short_description: Manage host network adapter configuration in System Center Virtual Machine Manager
description:
  - Configure host network adapter settings in SCVMM.
  - Can associate or remove logical networks on physical host NICs.
  - Can configure placement availability and description.
  - This module configures existing adapters and cannot create or delete them.
options:
  vm_host:
    description:
      - FQDN of the VM host whose adapter to configure.
    type: str
    required: true
  adapter_name:
    description:
      - Name of the network adapter to configure.
      - This is the adapter device name, not the connection name.
    type: str
    required: true
  logical_network:
    description:
      - Name of the logical network to associate with or remove from the adapter.
      - Use I(logical_network_action) to control whether to add or remove.
      - This operates on a single logical network at a time. Existing logical network associations are preserved.
    type: str
  logical_network_action:
    description:
      - Action to take with the logical network.
      - C(set) adds the logical network to the adapter, preserving any existing associations (additive).
      - C(remove) removes the logical network association from the adapter.
    type: str
    choices: [set, remove]
  description:
    description:
      - Description for the adapter.
    type: str
  available_for_placement:
    description:
      - Whether the adapter is available for VM placement.
    type: bool
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Associate logical network with adapter
  microsoft.scvmm.scvmm_host_network_adapter:
    vm_host: host01.example.com
    adapter_name: "Intel(R) Ethernet Adapter"
    logical_network: Management
    vmm_server: scvmm.example.com

- name: Remove logical network from adapter
  microsoft.scvmm.scvmm_host_network_adapter:
    vm_host: host01.example.com
    adapter_name: "Intel(R) Ethernet Adapter"
    logical_network: OldNetwork
    logical_network_action: remove
    vmm_server: scvmm.example.com

- name: Configure adapter for placement
  microsoft.scvmm.scvmm_host_network_adapter:
    vm_host: host01.example.com
    adapter_name: "Intel(R) Ethernet Adapter"
    available_for_placement: true
    description: Production NIC
    vmm_server: scvmm.example.com
'''

RETURN = r'''
adapter:
  description: The configured network adapter details.
  returned: always
  type: dict
  contains:
    id:
      description: Adapter ID in SCVMM.
      type: str
      returned: always
    name:
      description: Adapter device name.
      type: str
      returned: always
    connection_name:
      description: Network connection name.
      type: str
      returned: always
    description:
      description: Adapter description.
      type: str
      returned: always
    logical_networks:
      description: List of associated logical network names.
      type: list
      elements: str
      returned: always
    available_for_placement:
      description: Whether available for VM placement.
      type: bool
      returned: always
    vm_host:
      description: FQDN of the VM host.
      type: str
      returned: always
'''
