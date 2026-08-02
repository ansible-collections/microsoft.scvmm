# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_virtual_hard_disk_info
version_added: "1.0.0"
short_description: Query virtual hard disks in System Center Virtual Machine Manager
description:
  - Retrieve information about virtual hard disks in the SCVMM library or attached to a VM.
  - Can query all VHDs, filter by name, or filter by VM.
  - When filtering by VM, returns bus, lun, and bus_type from the associated disk drive.
options:
  name:
    description:
      - Name of the virtual hard disk to query.
      - If not specified, returns all virtual hard disks.
    type: str
  vm_name:
    description:
      - Name of the VM to query VHDs for.
      - When specified, returns only VHDs attached to this VM with bus/lun details.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all virtual hard disks
  microsoft.scvmm.scvmm_virtual_hard_disk_info:
    vmm_server: scvmm.example.com
  register: all_vhds

- name: Get a specific VHD by name
  microsoft.scvmm.scvmm_virtual_hard_disk_info:
    name: "Blank Disk - Small.vhdx"
    vmm_server: scvmm.example.com
  register: vhd_info

- name: Get VHDs attached to a VM
  microsoft.scvmm.scvmm_virtual_hard_disk_info:
    vm_name: my-vm
    vmm_server: scvmm.example.com
  register: vm_vhds

- name: Display VHD details
  ansible.builtin.debug:
    msg: "VHD {{ item.name }} ({{ item.vhd_format }}) - {{ item.max_size_gb }}GB max on {{ item.library_server }}"
  loop: "{{ all_vhds.virtual_hard_disks }}"
'''

RETURN = r'''
virtual_hard_disks:
  description: List of virtual hard disks.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Virtual hard disk ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: VHD file name.
      type: str
      returned: always
      sample: "Blank Disk - Small.vhdx"
    description:
      description: VHD description.
      type: str
      returned: when available
      sample: Default blank disk
    location:
      description: Full UNC path to the VHD file.
      type: str
      returned: always
      sample: "\\\\server\\Library\\VHDs\\disk.vhdx"
    directory:
      description: Directory containing the VHD.
      type: str
      returned: when available
      sample: "\\\\server\\Library\\VHDs"
    vhd_format:
      description: Format of the virtual hard disk.
      type: str
      returned: when available
      sample: VHDX
    vhd_type:
      description: Type of the virtual hard disk.
      type: str
      returned: when available
      sample: DynamicallyExpanding
    size_gb:
      description: Current size in gigabytes.
      type: float
      returned: when available
      sample: 0.5
    max_size_gb:
      description: Maximum size in gigabytes.
      type: float
      returned: when available
      sample: 16.0
    enabled:
      description: Whether the VHD is enabled in the library.
      type: bool
      returned: always
      sample: true
    is_orphaned:
      description: Whether the VHD is orphaned.
      type: bool
      returned: always
      sample: false
    library_server:
      description: Name of the library server hosting the VHD.
      type: str
      returned: when VHD is in a library
      sample: "scvmm-lib.example.com"
    vm_name:
      description: Name of the VM the VHD is attached to.
      type: str
      returned: when filtered by vm_name
      sample: my-vm
    bus:
      description: Bus number of the disk drive containing the VHD.
      type: int
      returned: when filtered by vm_name
      sample: 0
    lun:
      description: LUN of the disk drive containing the VHD.
      type: int
      returned: when filtered by vm_name
      sample: 0
    bus_type:
      description: Bus type of the disk drive containing the VHD.
      type: str
      returned: when filtered by vm_name
      sample: SCSI
'''
