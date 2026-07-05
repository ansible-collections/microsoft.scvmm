# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm
short_description: Manage SCVMM virtual machines
description:
  - Create, update, or delete virtual machines in System Center Virtual Machine Manager (SCVMM).
  - Supports VM creation from templates or from scratch.
  - Allows configuration of CPU, memory, and placement options.
options:
  name:
    description:
      - Name of the virtual machine.
    type: str
    required: true
  state:
    description:
      - Desired state of the virtual machine.
      - C(present) ensures the VM exists and is configured as specified.
      - C(absent) ensures the VM is removed.
    type: str
    choices: [ present, absent ]
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
      - If not specified, defaults to localhost.
    type: str
  template:
    description:
      - VM template name to create the VM from.
      - Only used during VM creation.
    type: str
  vm_host:
    description:
      - Hyper-V host to place the VM on.
      - Required if O(cloud) and O(host_group) are not specified.
    type: str
  cloud:
    description:
      - Cloud to deploy the VM into.
      - Mutually exclusive with O(vm_host) and O(host_group).
    type: str
  host_group:
    description:
      - Host group for automatic VM placement.
      - Mutually exclusive with O(vm_host) and O(cloud).
    type: str
  description:
    description:
      - Description of the virtual machine.
    type: str
  cpu_count:
    description:
      - Number of virtual CPUs to assign to the VM.
    type: int
  memory_mb:
    description:
      - Amount of memory in MB to assign to the VM.
    type: int
  dynamic_memory:
    description:
      - Enable dynamic memory for the VM.
      - When not specified, dynamic memory settings are not modified.
    type: bool
  hardware_profile:
    description:
      - Hardware profile to use for the VM.
      - Defines CPU, memory, and other hardware settings.
    type: str
  generation:
    description:
      - VM generation (1 or 2).
      - Only used during VM creation, cannot be changed on existing VMs.
      - Generation 2 VMs support UEFI and are recommended for modern operating systems.
    type: int
    choices: [ 1, 2 ]
  path:
    description:
      - File system path on the host where VM files will be stored.
      - If not specified and O(vm_host) is used, the host's default VM path is used automatically.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create VM from template
  microsoft.scvmm.scvmm_vm:
    name: TestVM01
    state: present
    vmm_server: scvmm01.example.com
    template: Windows2022Template
    vm_host: hyperv01.example.com
    description: Test virtual machine

- name: Create VM with specific resources
  microsoft.scvmm.scvmm_vm:
    name: TestVM02
    state: present
    vmm_server: scvmm01.example.com
    vm_host: hyperv01.example.com
    cpu_count: 4
    memory_mb: 8192
    dynamic_memory: true
    generation: 2
    description: High-performance VM

- name: Update VM resources
  microsoft.scvmm.scvmm_vm:
    name: TestVM01
    state: present
    cpu_count: 8
    memory_mb: 16384

- name: Deploy VM to cloud
  microsoft.scvmm.scvmm_vm:
    name: CloudVM01
    state: present
    cloud: Production
    template: UbuntuTemplate
    hardware_profile: Standard_DS2_v2

- name: Remove VM
  microsoft.scvmm.scvmm_vm:
    name: TestVM01
    state: absent
    vmm_server: scvmm01.example.com
'''

RETURN = r'''
name:
  description: Name of the virtual machine.
  returned: always
  type: str
  sample: TestVM01
state:
  description: Current state of the virtual machine.
  returned: always
  type: str
  sample: present
vm:
  description: Virtual machine details.
  returned: when state is present
  type: dict
  contains:
    id:
      description: VM unique identifier.
      type: str
      sample: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    name:
      description: VM name.
      type: str
      sample: TestVM01
    status:
      description: VM status.
      type: str
      sample: Running
    host:
      description: Hyper-V host the VM is running on.
      type: str
      sample: hyperv01.example.com
    cpu_count:
      description: Number of virtual CPUs.
      type: int
      sample: 4
    memory_mb:
      description: Memory in MB.
      type: int
      sample: 8192
    generation:
      description: VM generation.
      type: int
      sample: 2
    description:
      description: VM description.
      type: str
      sample: Test virtual machine
'''
