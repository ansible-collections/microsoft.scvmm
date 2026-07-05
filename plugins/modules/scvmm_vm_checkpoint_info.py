#!/usr/bin/python

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_checkpoint_info
short_description: Retrieve checkpoint information for SCVMM virtual machines
description:
  - Query checkpoint (snapshot) information from SCVMM virtual machines.
  - Can filter by checkpoint name or return all checkpoints on a VM.
options:
  vm_name:
    description:
      - Name of the virtual machine to query checkpoints for.
    type: str
    required: true
  name:
    description:
      - Name of a specific checkpoint to retrieve.
      - If not specified, all checkpoints on the VM are returned.
    type: str
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
- name: Get all checkpoints on a VM
  microsoft.scvmm.scvmm_vm_checkpoint_info:
    vm_name: TestVM01
    vmm_server: scvmm01.contoso.com
  register: all_checkpoints

- name: Get a specific checkpoint by name
  microsoft.scvmm.scvmm_vm_checkpoint_info:
    vm_name: TestVM01
    name: BeforeUpdate
    vmm_server: scvmm01.contoso.com
  register: checkpoint_info

- name: Display checkpoint details
  debug:
    msg: "Checkpoint {{ item.name }} created at {{ item.creation_time }}"
  loop: "{{ all_checkpoints.checkpoints }}"
'''

RETURN = r'''
checkpoints:
  description: List of checkpoints on the virtual machine.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Unique identifier of the checkpoint.
      type: str
      returned: always
      sample: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    name:
      description: Name of the checkpoint.
      type: str
      returned: always
      sample: "BeforeUpdate"
    description:
      description: Description of the checkpoint.
      type: str
      returned: when available
      sample: "Checkpoint before applying updates"
    creation_time:
      description: When the checkpoint was created in ISO 8601 format.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00.0000000Z"
'''
