# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_info
short_description: Retrieve information about SCVMM virtual machines
description:
  - Query virtual machine information from SCVMM.
  - Can filter by name to retrieve a specific VM, or return all VMs.
options:
  name:
    description:
      - The name of the virtual machine to query.
      - If not specified, all VMs are returned.
    type: str
  vmm_server:
    description:
      - The SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all virtual machines
  microsoft.scvmm.scvmm_vm_info:
    vmm_server: scvmm01.example.com
  register: all_vms

- name: Get specific virtual machine by name
  microsoft.scvmm.scvmm_vm_info:
    name: WebServer01
    vmm_server: scvmm01.example.com
  register: vm_info

- name: Display VM status and host
  microsoft.scvmm.scvmm_vm_info:
    name: WebServer01
  register: vm_result
- debug:
    msg: "VM {{ item.name }} is {{ item.status }} on host {{ item.host }}"
  loop: "{{ vm_result.virtual_machines }}"
'''

RETURN = r'''
virtual_machines:
    description: List of virtual machines.
    returned: always
    type: list
    elements: dict
    contains:
        id:
            description: The unique identifier of the virtual machine.
            type: str
            returned: always
            sample: "12345678-1234-1234-1234-123456789012"
        name:
            description: The name of the virtual machine.
            type: str
            returned: always
            sample: "WebServer01"
        status:
            description: The current status of the virtual machine.
            type: str
            returned: always
            sample: "Running"
        host:
            description: The name of the host where the VM is running.
            type: str
            returned: when available
            sample: "hyperv01.example.com"
        cpu_count:
            description: The number of CPUs allocated to the virtual machine.
            type: int
            returned: always
            sample: 4
        memory_mb:
            description: The amount of memory allocated to the VM in megabytes.
            type: int
            returned: always
            sample: 8192
        generation:
            description: The generation of the virtual machine (1 or 2).
            type: int
            returned: always
            sample: 2
        description:
            description: The description of the virtual machine.
            type: str
            returned: when available
            sample: "Production web server"
        cloud:
            description: The name of the cloud the VM belongs to.
            type: str
            returned: when available
            sample: "Production Cloud"
        creation_time:
            description: The creation time of the virtual machine in ISO 8601 format.
            type: str
            returned: when available
            sample: "2026-01-15T10:30:00.0000000Z"
        operating_system:
            description: The operating system name of the virtual machine.
            type: str
            returned: when available
            sample: "Windows Server 2022 Datacenter"
'''
