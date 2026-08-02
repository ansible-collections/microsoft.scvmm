#!/usr/bin/python

# Copyright: (c) 2025, Microsoft Corporation
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: scvmm_vm_clone
version_added: "1.0.0"
short_description: Clone a virtual machine in System Center Virtual Machine Manager
description:
  - Clone an existing virtual machine in SCVMM.
  - Can optionally specify target host or cloud for the cloned VM.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the new cloned virtual machine.
    type: str
    required: true
  source_vm:
    description:
      - Name of the source virtual machine to clone.
    type: str
    required: true
  vm_host:
    description:
      - Target host for the cloned VM.
      - If not specified, the source VM's current host is used.
      - Mutually exclusive with O(cloud).
    type: str
    required: false
  cloud:
    description:
      - Cloud to deploy the cloned VM into.
      - Mutually exclusive with O(vm_host).
    type: str
    required: false
  vmm_server:
    description:
      - The SCVMM server to connect to.
      - If not specified, uses the default SCVMM server.
    type: str
    required: false
  state:
    description:
      - Desired state of the cloned virtual machine.
      - C(present) ensures the cloned VM exists.
      - C(absent) ensures the cloned VM is removed.
    type: str
    choices: [ present, absent ]
    default: present
  description:
    description:
      - Description for the cloned virtual machine.
    type: str
    required: false
  path:
    description:
      - File system path on the host where cloned VM files will be stored.
      - If not specified and O(vm_host) is used, the host's default VM path is used automatically.
    type: str
    required: false
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Clone a VM to a specific host
  microsoft.scvmm.scvmm_vm_clone:
    name: WebServer02
    source_vm: WebServer01
    vm_host: HyperV-Host-01
    description: Cloned web server for testing
    state: present

- name: Clone a VM to a cloud
  microsoft.scvmm.scvmm_vm_clone:
    name: AppServer-Clone
    source_vm: AppServer-Template
    cloud: Production-Cloud
    vmm_server: scvmm.example.com
    state: present

- name: Remove a cloned VM
  microsoft.scvmm.scvmm_vm_clone:
    name: TestVM-Clone
    source_vm: TestVM
    state: absent

- name: Clone a VM with check mode
  microsoft.scvmm.scvmm_vm_clone:
    name: Database-Clone
    source_vm: Database-Master
    vm_host: HyperV-Host-02
    state: present
  check_mode: true
'''

RETURN = r'''
vm:
  description: Details of the cloned virtual machine.
  returned: when state is present and VM exists
  type: dict
  contains:
    id:
      description: VM ID in SCVMM.
      type: str
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: VM name.
      type: str
      sample: WebServer02
    status:
      description: Current status of the VM.
      type: str
      sample: Running
    host:
      description: Host where the VM is located.
      type: str
      sample: HyperV-Host-01
'''
