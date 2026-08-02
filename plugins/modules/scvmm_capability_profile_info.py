# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_capability_profile_info
version_added: "1.0.0"
short_description: Query capability profiles in System Center Virtual Machine Manager
description:
  - Query capability profiles from SCVMM.
  - Returns all profiles or a specific profile by name.
options:
  name:
    description:
      - Name of the capability profile to query.
      - If not specified, returns all profiles.
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
- name: Get all capability profiles
  microsoft.scvmm.scvmm_capability_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific capability profile
  microsoft.scvmm.scvmm_capability_profile_info:
    name: Standard-Cloud-Profile
    vmm_server: scvmm.example.com
  register: profile
'''

RETURN = r'''
capability_profiles:
  description: List of capability profiles.
  returned: always
  type: list
  elements: dict
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
