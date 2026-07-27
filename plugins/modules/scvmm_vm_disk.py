# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_vm_disk
short_description: Manage virtual disk drives on SCVMM virtual machines
description:
  - Manages virtual disk drives on virtual machines in System Center Virtual Machine Manager.
  - Supports creating new VHDs, attaching existing VHDs, updating settings, expanding,
    compressing, converting, validating, and removing disk drives.
  - Disk drives are identified by the combination of I(vm_name), I(bus_type), I(bus), and I(lun).
options:
  vm_name:
    description:
      - Name of the virtual machine.
    type: str
    required: true
  bus_type:
    description:
      - Bus type for the disk drive.
    type: str
    choices: [ ide, scsi ]
    default: scsi
  bus:
    description:
      - Bus number for the disk drive.
    type: int
    default: 0
  lun:
    description:
      - LUN (logical unit number) for the disk drive.
    type: int
    default: 0
  state:
    description:
      - Desired state of the disk drive.
      - C(present) ensures the disk drive exists at the specified bus and LUN.
      - C(absent) ensures the disk drive is removed.
    type: str
    choices: [ present, absent ]
    default: present
  vhd_name:
    description:
      - Name of an existing virtual hard disk to attach.
      - Mutually exclusive with I(size_gb) for creation; when both are provided, I(vhd_name) takes priority.
    type: str
  size_gb:
    description:
      - Size in GB for a new virtual hard disk, or target size for expanding an existing disk.
      - When the disk drive does not exist and I(vhd_name) is not provided, a new VHD of this size is created.
      - When the disk drive already exists, the disk is expanded to this size if it is larger than the current size.
    type: int
  vhd_format:
    description:
      - Format for a newly created virtual hard disk.
    type: str
    choices: [ VHDX, VHD ]
  vhd_type:
    description:
      - Type for a newly created virtual hard disk.
    type: str
    choices: [ Dynamic, Fixed ]
  path:
    description:
      - Path where the new virtual hard disk file should be created.
    type: str
  file_name:
    description:
      - File name for the new virtual hard disk.
    type: str
  shared_storage:
    description:
      - Whether the disk drive uses shared storage.
    type: bool
  volume_type:
    description:
      - Volume type for the disk drive.
    type: str
    choices: [ Boot, System, None ]
  iops_maximum:
    description:
      - Maximum IOPS limit for the disk drive.
      - Set to C(0) to remove the limit.
    type: int
  compress:
    description:
      - Compact the virtual hard disk to reclaim unused space.
      - Only applies when the disk drive already exists.
    type: bool
    default: false
  convert_to_format:
    description:
      - Convert the virtual hard disk to this format.
      - Only applies when the disk drive already exists.
    type: str
    choices: [ VHDX, VHD ]
  convert_to_type:
    description:
      - Convert the virtual hard disk to this type.
      - Only applies when the disk drive already exists.
    type: str
    choices: [ Dynamic, Fixed ]
  validate:
    description:
      - Validate the disk drive.
      - Results are returned in the I(validation) key.
    type: bool
    default: false
  delete_vhd:
    description:
      - When I(state=absent), also delete the associated VHD file.
      - By default the VHD file is kept when the disk drive is removed.
    type: bool
    default: false
  vmm_server:
    description:
      - Hostname or IP address of the SCVMM server.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create and attach a new 40 GB dynamic VHDX disk
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    size_gb: 40
    vhd_format: VHDX
    vhd_type: Dynamic
    state: present
    vmm_server: scvmm01.contoso.com

- name: Attach an existing VHD to a VM
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 2
    vhd_name: DataDisk01
    state: present
    vmm_server: scvmm01.contoso.com

- name: Expand disk to 80 GB
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    size_gb: 80
    state: present
    vmm_server: scvmm01.contoso.com

- name: Compress a disk drive
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    compress: true
    state: present
    vmm_server: scvmm01.contoso.com

- name: Convert disk to fixed VHDX
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    convert_to_format: VHDX
    convert_to_type: Fixed
    state: present
    vmm_server: scvmm01.contoso.com

- name: Validate a disk drive
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    validate: true
    state: present
    vmm_server: scvmm01.contoso.com
  register: disk_result

- name: Remove disk drive (keep VHD file)
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    state: absent
    vmm_server: scvmm01.contoso.com

- name: Remove disk drive and delete VHD file
  microsoft.scvmm.scvmm_vm_disk:
    vm_name: TestVM01
    bus_type: scsi
    bus: 0
    lun: 1
    state: absent
    delete_vhd: true
    vmm_server: scvmm01.contoso.com
'''

RETURN = r'''
vm_disk:
  description: Information about the disk drive.
  returned: when state is present
  type: dict
  contains:
    id:
      description: SCVMM ID of the disk drive.
      type: str
    name:
      description: Display name of the disk drive.
      type: str
    vm_name:
      description: Name of the virtual machine.
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
      description: Name of the attached virtual hard disk.
      type: str
    vhd_location:
      description: File path of the virtual hard disk.
      type: str
    vhd_format:
      description: Format of the VHD (VHDX or VHD).
      type: str
    vhd_type:
      description: Type of the VHD (DynamicallyExpanding, Fixed, etc.).
      type: str
    size_gb:
      description: Maximum size of the VHD in GB.
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
validation:
  description: Result of disk drive validation when I(validate=true).
  returned: when validate is true
  type: raw
'''
