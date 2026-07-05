#!/usr/bin/python

# Copyright: (c) 2025, Microsoft Corporation
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: scvmm_vm_checkpoint
short_description: Manage VM checkpoints in System Center Virtual Machine Manager
description:
  - Create, remove, or revert VM checkpoints (snapshots) in SCVMM.
  - Supports check mode for safe operation testing.
options:
  vm_name:
    description:
      - Name of the virtual machine to manage checkpoints for.
    type: str
    required: true
  name:
    description:
      - Name of the checkpoint to create, remove, or revert.
    type: str
    required: true
  state:
    description:
      - Desired state of the checkpoint.
      - C(present) ensures the checkpoint exists.
      - C(absent) ensures the checkpoint is removed.
      - C(reverted) restores the VM to the checkpoint state.
    type: str
    choices: [ present, absent, reverted ]
    default: present
  vmm_server:
    description:
      - Hostname or IP address of the SCVMM server.
      - If not specified, uses the default SCVMM server connection.
    type: str
  description:
    description:
      - Description for the checkpoint.
      - Only used when creating a new checkpoint (state=present).
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a VM checkpoint
  microsoft.scvmm.scvmm_vm_checkpoint:
    vm_name: TestVM01
    name: BeforeUpdate
    description: Checkpoint before applying updates
    state: present

- name: Remove a VM checkpoint
  microsoft.scvmm.scvmm_vm_checkpoint:
    vm_name: TestVM01
    name: BeforeUpdate
    state: absent

- name: Revert VM to a checkpoint
  microsoft.scvmm.scvmm_vm_checkpoint:
    vm_name: TestVM01
    name: BeforeUpdate
    state: reverted

- name: Create checkpoint on specific SCVMM server
  microsoft.scvmm.scvmm_vm_checkpoint:
    vm_name: ProdVM01
    name: PreMigration
    description: Before datacenter migration
    vmm_server: scvmm01.contoso.com
    state: present
'''

RETURN = r'''
checkpoint:
  description: Details of the checkpoint.
  returned: when checkpoint exists
  type: dict
  contains:
    id:
      description: Unique identifier of the checkpoint.
      type: str
      sample: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    creation_time:
      description: When the checkpoint was created.
      type: str
      sample: "2025-01-15T10:30:00Z"
    description:
      description: Description of the checkpoint.
      type: str
      sample: "Checkpoint before applying updates"
'''
