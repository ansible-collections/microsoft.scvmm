#!/usr/bin/python

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_scsi_adapter
short_description: Manage virtual SCSI adapters on SCVMM virtual machines
description:
  - Create, update, or remove virtual SCSI adapters on SCVMM virtual machines.
  - Supports shared SCSI adapters for clustering scenarios.
  - When creating, SCVMM auto-assigns the adapter ID.
  - Use O(scsi_adapter_id) (the adapter GUID) or O(adapter_id) to identify existing adapters.
options:
  vm_name:
    description:
      - Name of the virtual machine to manage SCSI adapters on.
    type: str
    required: true
  state:
    description:
      - Desired state of the SCSI adapter.
      - C(present) ensures the SCSI adapter exists with specified configuration.
      - C(absent) ensures the SCSI adapter is removed.
    type: str
    choices: [ present, absent ]
    default: present
  vmm_server:
    description:
      - SCVMM server hostname or IP address.
      - If not specified, uses the default SCVMM server connection.
    type: str
  adapter_id:
    description:
      - SCSI adapter slot number used to identify an existing adapter.
      - This value is assigned by SCVMM and cannot be changed after creation.
      - On Gen1 VMs this is unique per adapter; on Gen2 VMs all adapters share the same value (255).
      - ESX hosts use ID 7 for the bus-sharing adapter.
      - For Gen2 VMs, use O(scsi_adapter_id) instead to target a specific adapter.
      - When O(state=present) and no adapter is found, a new adapter is created.
      - At least one of O(adapter_id) or O(scsi_adapter_id) is required when O(state=absent).
    type: int
  scsi_adapter_id:
    description:
      - The unique GUID of the SCSI adapter.
      - Takes precedence over O(adapter_id) when both are specified.
      - Obtain this value from the return value of a previous create or from the info module.
    type: str
  shared:
    description:
      - Enable shared SCSI adapter for clustering scenarios.
      - Only applicable when O(state=present).
    type: bool
    default: false
notes:
  - This module requires the VirtualMachineManager PowerShell module.
  - Check mode is supported.
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Add a SCSI adapter to a VM
  microsoft.scvmm.scvmm_vm_scsi_adapter:
    vm_name: TestVM01
    state: present
    vmm_server: scvmm01.contoso.com
  register: new_adapter

- name: Update a specific adapter by GUID
  microsoft.scvmm.scvmm_vm_scsi_adapter:
    vm_name: TestVM01
    scsi_adapter_id: "{{ new_adapter.scsi_adapter.id }}"
    shared: true
    state: present
    vmm_server: scvmm01.contoso.com

- name: Remove a specific SCSI adapter by GUID
  microsoft.scvmm.scvmm_vm_scsi_adapter:
    vm_name: TestVM01
    scsi_adapter_id: "{{ new_adapter.scsi_adapter.id }}"
    state: absent
    vmm_server: scvmm01.contoso.com

- name: Remove SCSI adapter by adapter_id (Gen1 VMs)
  microsoft.scvmm.scvmm_vm_scsi_adapter:
    vm_name: TestVM01
    adapter_id: 1
    state: absent
    vmm_server: scvmm01.contoso.com
'''

RETURN = r'''
scsi_adapter:
  description: Details of the SCSI adapter.
  returned: when state is present
  type: dict
  contains:
    id:
      description: Unique GUID of the SCSI adapter.
      type: str
      sample: "12345678-1234-1234-1234-123456789012"
    adapter_id:
      description: SCSI adapter slot/ID number assigned by SCVMM.
      type: int
      sample: 0
    shared:
      description: Whether the SCSI adapter is shared.
      type: bool
      sample: false
'''
