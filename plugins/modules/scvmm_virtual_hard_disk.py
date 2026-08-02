# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_virtual_hard_disk
version_added: "1.0.0"
short_description: Manage virtual hard disks in System Center Virtual Machine Manager
description:
  - Update properties or remove virtual hard disks in the SCVMM library.
  - Uses Set-SCVirtualHardDisk to update VHD properties.
  - Uses Remove-SCVirtualHardDisk to delete VHDs from the library.
  - VHDs are created as part of VM or template operations and cannot be created standalone.
options:
  name:
    description:
      - Name of the virtual hard disk file.
    type: str
    required: true
  description:
    description:
      - Description of the virtual hard disk.
    type: str
  enabled:
    description:
      - Whether the VHD is enabled in the library.
    type: bool
  state:
    description:
      - Desired state of the virtual hard disk.
      - C(present) updates properties of an existing VHD.
      - C(absent) removes the VHD from the library.
    type: str
    choices: ['present', 'absent']
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Update VHD description
  microsoft.scvmm.scvmm_virtual_hard_disk:
    name: "Blank Disk - Small.vhdx"
    description: Default blank dynamic disk
    state: present
    vmm_server: scvmm.example.com

- name: Disable a VHD in the library
  microsoft.scvmm.scvmm_virtual_hard_disk:
    name: "old-disk.vhdx"
    enabled: false
    state: present
    vmm_server: scvmm.example.com

- name: Remove a VHD from the library
  microsoft.scvmm.scvmm_virtual_hard_disk:
    name: "temp-disk.vhdx"
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
virtual_hard_disk:
  description: Details of the virtual hard disk.
  returned: when state is present and VHD exists
  type: dict
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
      description: Library server hosting the VHD.
      type: str
      returned: when available
      sample: "server.example.com"
'''
