# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_hardware_profile_info
version_added: "1.0.0"
short_description: Query hardware profiles in System Center Virtual Machine Manager
description:
  - Retrieve information about hardware profiles in SCVMM.
  - Can query all profiles or filter by name.
options:
  name:
    description:
      - Name of the hardware profile to query.
      - If not specified, returns all hardware profiles.
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
- name: Get all hardware profiles
  microsoft.scvmm.scvmm_hardware_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific hardware profile
  microsoft.scvmm.scvmm_hardware_profile_info:
    name: WebServer-HW
    vmm_server: scvmm.example.com
  register: profile_info
'''

RETURN = r'''
hardware_profiles:
  description: List of hardware profiles.
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
    owner:
      description: Profile owner.
      type: str
      returned: when available
    cpu_count:
      description: Number of CPUs.
      type: int
      returned: always
    memory_mb:
      description: Memory in MB.
      type: int
      returned: always
    dynamic_memory:
      description: Whether dynamic memory is enabled.
      type: bool
      returned: always
    dynamic_memory_minimum_mb:
      description: Minimum dynamic memory in MB.
      type: int
      returned: when available
    dynamic_memory_maximum_mb:
      description: Maximum dynamic memory in MB.
      type: int
      returned: when available
    generation:
      description: VM generation.
      type: int
      returned: always
    highly_available:
      description: Whether highly available.
      type: bool
      returned: always
    ha_vm_priority:
      description: HA restart priority (3000 High, 2000 Medium, 1000 Low, 0 no auto-restart).
      type: int
      returned: always
    secure_boot_enabled:
      description: Whether secure boot is enabled.
      type: bool
      returned: always
    checkpoint_type:
      description: Checkpoint type.
      type: str
      returned: when available
    cpu_expected_utilization_percent:
      description: Expected CPU utilization percentage.
      type: int
      returned: when available
    cpu_maximum_percent:
      description: Maximum CPU percentage.
      type: int
      returned: when available
    cpu_relative_weight:
      description: CPU relative weight.
      type: int
      returned: when available
    cpu_reserve:
      description: CPU reserve percentage.
      type: int
      returned: when available
    network_utilization_mbps:
      description: Network bandwidth in Mbps.
      type: int
      returned: when available
    disk_iops:
      description: Disk IOPS.
      type: int
      returned: when available
    creation_time:
      description: When the profile was created in ISO 8601 format.
      type: str
      returned: when available
'''
