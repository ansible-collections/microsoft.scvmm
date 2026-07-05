#!/usr/bin/python

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_scsi_adapter_info
short_description: Retrieve SCSI adapter information for SCVMM virtual machines
description:
  - Query virtual SCSI adapter information from SCVMM virtual machines.
  - Returns all SCSI adapters attached to a VM.
options:
  vm_name:
    description:
      - Name of the virtual machine to query SCSI adapters for.
    type: str
    required: true
  vmm_server:
    description:
      - SCVMM server hostname or IP address.
      - If not specified, uses the default SCVMM server connection.
    type: str
notes:
  - This module requires the VirtualMachineManager PowerShell module.
  - This is an info module and does not make any changes.
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all SCSI adapters on a VM
  microsoft.scvmm.scvmm_vm_scsi_adapter_info:
    vm_name: TestVM01
    vmm_server: scvmm01.contoso.com
  register: scsi_info

- name: Display SCSI adapter details
  debug:
    msg: "Adapter {{ item.adapter_id }}: shared={{ item.shared }}"
  loop: "{{ scsi_info.scsi_adapters }}"
'''

RETURN = r'''
scsi_adapters:
  description: List of SCSI adapters on the virtual machine.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Unique identifier of the SCSI adapter.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    adapter_id:
      description: SCSI adapter slot/ID number.
      type: int
      returned: always
      sample: 0
    shared:
      description: Whether the SCSI adapter is shared.
      type: bool
      returned: always
      sample: false
'''
