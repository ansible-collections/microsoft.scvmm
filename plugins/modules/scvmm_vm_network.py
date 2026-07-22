# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_network
short_description: Manage VM networks in System Center Virtual Machine Manager
description:
  - Create, update, or remove VM networks in SCVMM.
  - A VM network is associated with a logical network and provides network connectivity to virtual machines.
  - Uses New-SCVMNetwork to create new VM networks.
  - Uses Set-SCVMNetwork to update existing VM networks.
  - Uses Remove-SCVMNetwork to delete VM networks.
options:
  name:
    description:
      - Name of the VM network.
    type: str
    required: true
  logical_network:
    description:
      - Name of the parent logical network.
      - Required when I(state=present).
    type: str
  description:
    description:
      - Description of the VM network.
    type: str
  isolation_type:
    description:
      - Isolation type for the VM network.
      - Can only be set at creation time.
    type: str
    choices: ['NoIsolation', 'WindowsNetworkVirtualization', 'VLANNetwork', 'External']
  state:
    description:
      - Desired state of the VM network.
      - C(present) creates or updates a VM network.
      - C(absent) removes a VM network.
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
- name: Create a VM network
  microsoft.scvmm.scvmm_vm_network:
    name: Tenant-VMNet
    logical_network: Management-LN
    description: Tenant VM network
    state: present
    vmm_server: scvmm.example.com

- name: Update VM network description
  microsoft.scvmm.scvmm_vm_network:
    name: Tenant-VMNet
    logical_network: Management-LN
    description: Updated tenant network
    state: present
    vmm_server: scvmm.example.com

- name: Remove a VM network
  microsoft.scvmm.scvmm_vm_network:
    name: Tenant-VMNet
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
vm_network:
  description: Details of the VM network.
  returned: when state is present and VM network exists
  type: dict
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
