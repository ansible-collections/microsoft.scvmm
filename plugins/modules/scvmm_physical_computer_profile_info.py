# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_physical_computer_profile_info
version_added: "1.1.0"
short_description: Get information about physical computer profiles in SCVMM
description:
  - Retrieves information about physical computer profiles from SCVMM.
  - Can list all profiles or filter by name.
options:
  name:
    description:
      - Name of a specific physical computer profile to retrieve.
      - If not specified, all profiles are returned.
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
- name: Get all physical computer profiles
  microsoft.scvmm.scvmm_physical_computer_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific physical computer profile
  microsoft.scvmm.scvmm_physical_computer_profile_info:
    name: WorkgroupHost
    vmm_server: scvmm.example.com
  register: profile_info

- name: Display profile details
  ansible.builtin.debug:
    var: profile_info.physical_computer_profiles
'''

RETURN = r'''
physical_computer_profiles:
  description: List of physical computer profiles.
  returned: always
  type: list
  elements: dict
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
      sample: "WorkgroupHost"
    description:
      description: Profile description.
      type: str
      returned: when available
    owner:
      description: Profile owner.
      type: str
      returned: when available
    full_name:
      description: Full name for OS setup.
      type: str
      returned: when available
    organization_name:
      description: Organization name for OS setup.
      type: str
      returned: when available
    join_domain:
      description: Domain the profile is configured to join.
      type: str
      returned: when available
    join_workgroup:
      description:
        - Workgroup name if configured for workgroup membership.
        - Returns the workgroup name string (e.g. C(WORKGROUP)), not a boolean.
      type: str
      returned: when available
      sample: "WORKGROUP"
    time_zone:
      description: Time zone index for the deployed server.
      type: int
      returned: when available
      sample: 35
    bypass_vhd_conversion:
      description: Whether VHD conversion is bypassed.
      type: bool
      returned: always
    is_guarded:
      description: Whether the profile is for guarded hosts.
      type: bool
      returned: always
    vm_paths:
      description: Default VM storage path.
      type: str
      returned: when available
    enabled:
      description: Whether the profile is enabled.
      type: bool
      returned: always
    os_boot_vhd:
      description: Name of the OS boot virtual hard disk.
      type: str
      returned: when available
    driver_matching_tag:
      description: List of driver matching tags for the profile.
      type: list
      elements: str
      returned: always
'''
