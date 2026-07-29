# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_hardware_profile
short_description: Manage hardware profiles in System Center Virtual Machine Manager
description:
  - Create, update, and remove hardware profiles in SCVMM.
  - Hardware profiles store hardware configuration templates for VM deployments.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the hardware profile.
    type: str
    required: true
  description:
    description:
      - Description for the hardware profile.
    type: str
  owner:
    description:
      - Owner of the hardware profile in DOMAIN\\User format.
    type: str
  cpu_count:
    description:
      - Number of CPUs for virtual machines using this profile.
    type: int
  memory_mb:
    description:
      - Amount of memory in MB for virtual machines using this profile.
    type: int
  dynamic_memory:
    description:
      - Whether dynamic memory is enabled.
    type: bool
  dynamic_memory_minimum_mb:
    description:
      - Minimum amount of memory in MB when dynamic memory is enabled.
    type: int
  dynamic_memory_maximum_mb:
    description:
      - Maximum amount of memory in MB when dynamic memory is enabled.
    type: int
  cpu_expected_utilization_percent:
    description:
      - Expected CPU utilization percentage on the host.
    type: int
  cpu_maximum_percent:
    description:
      - Maximum percentage of host CPU resources a VM can use.
    type: int
  cpu_relative_weight:
    description:
      - Relative weight for CPU resource allocation among VMs on the same host.
    type: int
  cpu_reserve:
    description:
      - Minimum percentage of host CPU reserved for the VM.
    type: int
  highly_available:
    description:
      - Whether VMs using this profile should be highly available.
    type: bool
  generation:
    description:
      - Virtual machine generation.
      - Only used during creation, cannot be changed on existing profiles.
    type: int
    choices: [1, 2]
  secure_boot_enabled:
    description:
      - Whether secure boot is enabled.
    type: bool
  checkpoint_type:
    description:
      - Checkpoint type for VMs using this profile.
    type: str
    choices: [Disabled, Production, ProductionOnly, Standard]
  network_utilization_mbps:
    description:
      - Network bandwidth in Mbps available to VMs using this profile.
    type: int
  disk_iops:
    description:
      - Number of disk IOPS available to VMs using this profile.
    type: int
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
  state:
    description:
      - Desired state of the hardware profile.
      - C(present) ensures the profile exists.
      - C(absent) ensures the profile is removed.
    type: str
    choices: [present, absent]
    default: present
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a basic hardware profile
  microsoft.scvmm.scvmm_hardware_profile:
    name: WebServer-HW
    cpu_count: 4
    memory_mb: 8192
    vmm_server: scvmm.example.com
    state: present

- name: Create a hardware profile with dynamic memory
  microsoft.scvmm.scvmm_hardware_profile:
    name: AppServer-HW
    cpu_count: 2
    memory_mb: 4096
    dynamic_memory: true
    dynamic_memory_minimum_mb: 2048
    dynamic_memory_maximum_mb: 8192
    state: present

- name: Update hardware profile description
  microsoft.scvmm.scvmm_hardware_profile:
    name: WebServer-HW
    description: Standard web server hardware
    state: present

- name: Remove a hardware profile
  microsoft.scvmm.scvmm_hardware_profile:
    name: OldHWProfile
    state: absent
'''

RETURN = r'''
hardware_profile:
  description: Details of the hardware profile.
  returned: when state is present and profile exists
  type: dict
  contains:
    id:
      description: Profile ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Profile name.
      type: str
      returned: always
      sample: WebServer-HW
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
      sample: 4
    memory_mb:
      description: Memory in MB.
      type: int
      returned: always
      sample: 8192
    dynamic_memory:
      description: Whether dynamic memory is enabled.
      type: bool
      returned: always
      sample: false
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
      sample: 2
    highly_available:
      description: Whether highly available.
      type: bool
      returned: always
      sample: false
    secure_boot_enabled:
      description: Whether secure boot is enabled.
      type: bool
      returned: always
      sample: true
    checkpoint_type:
      description: Checkpoint type.
      type: str
      returned: when available
      sample: Production
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
      description: When the profile was created.
      type: str
      returned: always
'''
