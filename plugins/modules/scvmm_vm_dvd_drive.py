#!/usr/bin/python

# Copyright: (c) 2025, Microsoft Corporation
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: scvmm_vm_dvd_drive
version_added: "1.0.0"
short_description: Manage virtual DVD drives on SCVMM virtual machines
description:
  - Manages virtual DVD drives on virtual machines in System Center Virtual Machine Manager.
  - Can add or remove DVD drives and mount ISO files from the SCVMM library.
options:
  vm_name:
    description:
      - Name of the virtual machine.
    type: str
    required: true
  state:
    description:
      - Desired state of the DVD drive.
      - C(present) ensures the DVD drive exists at the specified bus and LUN.
      - C(absent) ensures the DVD drive is removed.
    type: str
    choices: [ present, absent ]
    default: present
  vmm_server:
    description:
      - Hostname or IP address of the SCVMM server.
      - If not specified, uses the default SCVMM server connection.
    type: str
  bus:
    description:
      - IDE bus number for the DVD drive.
    type: int
    default: 0
  lun:
    description:
      - IDE LUN (logical unit number) for the DVD drive.
    type: int
    default: 1
  iso:
    description:
      - Name of the ISO file from the SCVMM library to mount in the DVD drive.
      - Only applicable when I(state=present).
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Add DVD drive to VM
  microsoft.scvmm.scvmm_vm_dvd_drive:
    vm_name: TestVM01
    state: present
    vmm_server: scvmm01.contoso.com

- name: Add DVD drive with ISO mounted
  microsoft.scvmm.scvmm_vm_dvd_drive:
    vm_name: TestVM01
    state: present
    bus: 0
    lun: 1
    iso: windows_server_2022.iso
    vmm_server: scvmm01.contoso.com

- name: Remove DVD drive from VM
  microsoft.scvmm.scvmm_vm_dvd_drive:
    vm_name: TestVM01
    state: absent
    bus: 0
    lun: 1
    vmm_server: scvmm01.contoso.com

- name: Mount different ISO on existing DVD drive
  microsoft.scvmm.scvmm_vm_dvd_drive:
    vm_name: TestVM01
    state: present
    bus: 0
    lun: 1
    iso: ubuntu_22.04.iso
'''

RETURN = r'''
dvd_drive:
  description: Information about the DVD drive.
  returned: when state is present
  type: dict
  contains:
    bus:
      description: IDE bus number.
      type: int
      sample: 0
    lun:
      description: IDE LUN number.
      type: int
      sample: 1
    iso:
      description: Name of the mounted ISO file, if any.
      type: str
      sample: windows_server_2022.iso
    id:
      description: SCVMM ID of the DVD drive.
      type: str
      sample: 12345678-1234-1234-1234-123456789012
'''
