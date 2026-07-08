#!/usr/bin/python

# Copyright: (c) 2026, Microsoft Corporation
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: scvmm_vm_state
short_description: Manage SCVMM virtual machine power state
description:
  - Manages the power state of virtual machines in System Center Virtual Machine Manager (SCVMM).
  - Supports starting, stopping, suspending, and saving VMs.
  - Provides idempotent state management with check mode and diff support.
options:
  name:
    description:
      - Name of the virtual machine to manage.
    type: str
    required: true
  state:
    description:
      - Desired power state of the virtual machine.
      - C(started) ensures the VM is running.
      - C(stopped) ensures the VM is powered off.
      - C(suspended) ensures the VM is paused.
      - C(saved) ensures the VM is saved.
    type: str
    required: true
    choices: [ started, stopped, suspended, saved ]
  vmm_server:
    description:
      - SCVMM server to connect to.
      - If not specified, uses the default connection settings.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
requirements:
  - Windows Server with SCVMM PowerShell module
  - SCVMM admin credentials
'''

EXAMPLES = r'''
- name: Start a virtual machine
  microsoft.scvmm.scvmm_vm_state:
    name: TestVM01
    state: started
    vmm_server: scvmm.example.com

- name: Stop a virtual machine gracefully
  microsoft.scvmm.scvmm_vm_state:
    name: TestVM01
    state: stopped

- name: Suspend a virtual machine
  microsoft.scvmm.scvmm_vm_state:
    name: TestVM01
    state: suspended

- name: Save a virtual machine state
  microsoft.scvmm.scvmm_vm_state:
    name: TestVM01
    state: saved
'''

RETURN = r'''
state:
  description: Current power state of the virtual machine.
  returned: always
  type: str
  sample: Running
previous_state:
  description: Previous power state of the virtual machine before the operation.
  returned: when state changed
  type: str
  sample: PowerOff
'''
