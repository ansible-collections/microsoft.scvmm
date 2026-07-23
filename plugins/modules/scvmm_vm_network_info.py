# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_network_info
short_description: Query VM networks in System Center Virtual Machine Manager
description:
  - Retrieve information about VM networks in SCVMM.
  - Can query all VM networks, filter by name, or filter by logical network.
options:
  name:
    description:
      - Name of the VM network to query.
      - If not specified, returns all VM networks.
    type: str
  logical_network:
    description:
      - Filter VM networks by parent logical network name.
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
- name: Get all VM networks
  microsoft.scvmm.scvmm_vm_network_info:
    vmm_server: scvmm.example.com
  register: all_vm_networks

- name: Get a specific VM network
  microsoft.scvmm.scvmm_vm_network_info:
    name: Tenant-VMNet
    vmm_server: scvmm.example.com
  register: vm_network_info

- name: Get VM networks for a logical network
  microsoft.scvmm.scvmm_vm_network_info:
    logical_network: Management-LN
    vmm_server: scvmm.example.com
  register: mgmt_vm_networks
'''

RETURN = r'''
vm_networks:
  description: List of VM networks.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: VM network ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: VM network name.
      type: str
      returned: always
      sample: Tenant-VMNet
    description:
      description: VM network description.
      type: str
      returned: when available
      sample: Tenant VM network
    logical_network:
      description: Name of the parent logical network.
      type: str
      returned: always
      sample: Management-LN
    isolation_type:
      description: Isolation type of the VM network.
      type: str
      returned: always
      sample: NoIsolation
'''
