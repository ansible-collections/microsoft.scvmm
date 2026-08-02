#!/usr/bin/python

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_dvd_drive_info
version_added: "1.0.0"
short_description: Retrieve DVD drive information for SCVMM virtual machines
description:
  - Query virtual DVD drive information from SCVMM virtual machines.
  - Returns all DVD drives attached to a VM.
options:
  vm_name:
    description:
      - Name of the virtual machine to query DVD drives for.
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
- name: Get all DVD drives on a VM
  microsoft.scvmm.scvmm_vm_dvd_drive_info:
    vm_name: TestVM01
    vmm_server: scvmm01.contoso.com
  register: dvd_info

- name: Display DVD drive details
  debug:
    msg: "DVD drive at bus {{ item.bus }} lun {{ item.lun }}, ISO: {{ item.iso | default('none') }}"
  loop: "{{ dvd_info.dvd_drives }}"
'''

RETURN = r'''
dvd_drives:
  description: List of DVD drives on the virtual machine.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Unique identifier of the DVD drive.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    bus:
      description: IDE bus number.
      type: int
      returned: always
      sample: 0
    lun:
      description: IDE LUN number.
      type: int
      returned: always
      sample: 1
    iso:
      description: Name of the mounted ISO file, if any.
      type: str
      returned: when available
      sample: "windows_server_2022.iso"
'''
