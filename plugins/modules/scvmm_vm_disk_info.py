# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_disk_info
version_added: "1.0.0"
short_description: Query virtual disk drives on VMs in SCVMM
description:
  - Retrieve information about virtual disk drives attached to a VM.
options:
  vm_name:
    description:
      - Name of the virtual machine to query disk drives for.
    type: str
    required: true
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get disk drives for a VM
  microsoft.scvmm.scvmm_vm_disk_info:
    vm_name: MyVM
    vmm_server: scvmm.example.com
  register: disk_info
'''

RETURN = r'''
disk_drives:
  description: List of virtual disk drives.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Disk drive ID.
      type: str
    name:
      description: Display name.
      type: str
    vm_name:
      description: VM name.
      type: str
    bus_type:
      description: Bus type (IDE or SCSI).
      type: str
    bus:
      description: Bus number.
      type: int
    lun:
      description: LUN number.
      type: int
    vhd_name:
      description: Name of the attached VHD.
      type: str
    vhd_location:
      description: File path of the VHD.
      type: str
    vhd_format:
      description: Format of the VHD (VHDX or VHD).
      type: str
    vhd_type:
      description: Type of the VHD.
      type: str
    size_gb:
      description: Maximum size in GB.
      type: float
    shared_storage:
      description: Whether shared storage is enabled.
      type: bool
    volume_type:
      description: Volume type.
      type: str
    iops_maximum:
      description: Maximum IOPS limit.
      type: int
    create_diff_disk:
      description: Whether differencing disk creation is enabled.
      type: bool
    enabled:
      description: Whether the disk drive is enabled.
      type: bool
'''
