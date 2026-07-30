# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_capability_profile
short_description: Manage capability profiles in System Center Virtual Machine Manager
description:
  - Create, update, and remove capability profiles in SCVMM.
  - Capability profiles define allowed VM configuration ranges for cloud deployments.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the capability profile.
    type: str
    required: true
  description:
    description:
      - Description for the capability profile.
    type: str
  fabric_capability_type:
    description:
      - The fabric type for the capability profile.
      - Required when creating a new profile.
      - Cannot be changed after creation.
    type: str
    choices: [ HyperV, ESX ]
  cpu_count_initial:
    description:
      - Initial CPU count.
    type: int
  cpu_count_minimum:
    description:
      - Minimum allowed CPU count.
    type: int
  cpu_count_maximum:
    description:
      - Maximum allowed CPU count.
    type: int
  memory_mb_initial:
    description:
      - Initial memory in MB.
    type: int
  memory_mb_minimum:
    description:
      - Minimum allowed memory in MB.
    type: int
  memory_mb_maximum:
    description:
      - Maximum allowed memory in MB.
    type: int
  dynamic_memory_value:
    description:
      - Whether dynamic memory is enabled.
    type: bool
  dynamic_memory_value_can_change:
    description:
      - Whether the dynamic memory setting can be changed by tenants.
    type: bool
  startup_memory_mb_initial:
    description:
      - Initial startup memory in MB for dynamic memory.
    type: int
  startup_memory_mb_minimum:
    description:
      - Minimum startup memory in MB.
    type: int
  startup_memory_mb_maximum:
    description:
      - Maximum startup memory in MB.
    type: int
  maximum_memory_mb_initial:
    description:
      - Initial maximum memory in MB for dynamic memory.
    type: int
  maximum_memory_mb_minimum:
    description:
      - Minimum value for maximum memory in MB.
    type: int
  maximum_memory_mb_maximum:
    description:
      - Maximum value for maximum memory in MB.
    type: int
  virtual_hard_disk_count_initial:
    description:
      - Initial number of virtual hard disks.
    type: int
  virtual_hard_disk_count_minimum:
    description:
      - Minimum number of virtual hard disks.
    type: int
  virtual_hard_disk_count_maximum:
    description:
      - Maximum number of virtual hard disks.
    type: int
  virtual_hard_disk_size_mb_initial:
    description:
      - Initial virtual hard disk size in MB.
    type: int
  virtual_hard_disk_size_mb_minimum:
    description:
      - Minimum virtual hard disk size in MB.
    type: int
  virtual_hard_disk_size_mb_maximum:
    description:
      - Maximum virtual hard disk size in MB.
    type: int
  virtual_dvd_drive_count_initial:
    description:
      - Initial number of virtual DVD drives.
    type: int
  virtual_dvd_drive_count_minimum:
    description:
      - Minimum number of virtual DVD drives.
    type: int
  virtual_dvd_drive_count_maximum:
    description:
      - Maximum number of virtual DVD drives.
    type: int
  virtual_network_adapter_count_initial:
    description:
      - Initial number of virtual network adapters.
    type: int
  virtual_network_adapter_count_minimum:
    description:
      - Minimum number of virtual network adapters.
    type: int
  virtual_network_adapter_count_maximum:
    description:
      - Maximum number of virtual network adapters.
    type: int
  vm_highly_available_value:
    description:
      - Whether VMs should be highly available.
    type: bool
  vm_highly_available_value_can_change:
    description:
      - Whether the HA setting can be changed by tenants.
    type: bool
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
  state:
    description:
      - Desired state of the capability profile.
      - C(present) ensures the profile exists.
      - C(absent) ensures the profile is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a capability profile
  microsoft.scvmm.scvmm_capability_profile:
    name: Standard-Cloud-Profile
    fabric_capability_type: HyperV
    description: Standard cloud capability profile
    cpu_count_initial: 2
    cpu_count_minimum: 1
    cpu_count_maximum: 8
    memory_mb_initial: 2048
    memory_mb_minimum: 512
    memory_mb_maximum: 16384
    vmm_server: scvmm.example.com
    state: present

- name: Update CPU limits
  microsoft.scvmm.scvmm_capability_profile:
    name: Standard-Cloud-Profile
    cpu_count_maximum: 16
    state: present

- name: Remove a capability profile
  microsoft.scvmm.scvmm_capability_profile:
    name: Standard-Cloud-Profile
    state: absent
'''

RETURN = r'''
capability_profile:
  description: Details of the capability profile.
  returned: when state is present and profile exists
  type: dict
  contains:
    id:
      description: Profile ID in SCVMM.
      type: str
      returned: always
    name:
      description: Profile name.
      type: str
      returned: always
    description:
      description: Profile description.
      type: str
      returned: when available
    fabric_capability_type:
      description: Fabric capability type.
      type: str
      returned: always
      sample: HyperV
    cpu_count_initial:
      description: Initial CPU count.
      type: int
      returned: always
    cpu_count_minimum:
      description: Minimum CPU count.
      type: int
      returned: always
    cpu_count_maximum:
      description: Maximum CPU count.
      type: int
      returned: always
    memory_mb_initial:
      description: Initial memory in MB.
      type: int
      returned: always
    memory_mb_minimum:
      description: Minimum memory in MB.
      type: int
      returned: always
    memory_mb_maximum:
      description: Maximum memory in MB.
      type: int
      returned: always
    dynamic_memory_value:
      description: Whether dynamic memory is enabled.
      type: bool
      returned: always
    dynamic_memory_value_can_change:
      description: Whether the dynamic memory setting can be changed.
      type: bool
      returned: always
    startup_memory_mb_initial:
      description: Initial startup memory in MB.
      type: int
      returned: always
    startup_memory_mb_minimum:
      description: Minimum startup memory in MB.
      type: int
      returned: always
    startup_memory_mb_maximum:
      description: Maximum startup memory in MB.
      type: int
      returned: always
    maximum_memory_mb_initial:
      description: Initial maximum memory in MB.
      type: int
      returned: always
    maximum_memory_mb_minimum:
      description: Minimum value for maximum memory in MB.
      type: int
      returned: always
    maximum_memory_mb_maximum:
      description: Maximum value for maximum memory in MB.
      type: int
      returned: always
    virtual_hard_disk_count_initial:
      description: Initial VHD count.
      type: int
      returned: always
    virtual_hard_disk_count_minimum:
      description: Minimum VHD count.
      type: int
      returned: always
    virtual_hard_disk_count_maximum:
      description: Maximum VHD count.
      type: int
      returned: always
    virtual_hard_disk_size_mb_initial:
      description: Initial VHD size in MB.
      type: int
      returned: always
    virtual_hard_disk_size_mb_minimum:
      description: Minimum VHD size in MB.
      type: int
      returned: always
    virtual_hard_disk_size_mb_maximum:
      description: Maximum VHD size in MB.
      type: int
      returned: always
    virtual_dvd_drive_count_initial:
      description: Initial DVD drive count.
      type: int
      returned: always
    virtual_dvd_drive_count_minimum:
      description: Minimum DVD drive count.
      type: int
      returned: always
    virtual_dvd_drive_count_maximum:
      description: Maximum DVD drive count.
      type: int
      returned: always
    virtual_network_adapter_count_initial:
      description: Initial network adapter count.
      type: int
      returned: always
    virtual_network_adapter_count_minimum:
      description: Minimum network adapter count.
      type: int
      returned: always
    virtual_network_adapter_count_maximum:
      description: Maximum network adapter count.
      type: int
      returned: always
    vm_highly_available_value:
      description: Whether VMs are highly available.
      type: bool
      returned: always
    vm_highly_available_value_can_change:
      description: Whether the HA setting can be changed.
      type: bool
      returned: always
'''
