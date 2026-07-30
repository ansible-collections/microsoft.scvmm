# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_guest_os_profile_info
short_description: Query guest OS profiles in System Center Virtual Machine Manager
description:
  - Query guest OS profiles from SCVMM.
  - Returns all profiles or a specific profile by name.
options:
  name:
    description:
      - Name of the guest OS profile to query.
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
- name: Get all guest OS profiles
  microsoft.scvmm.scvmm_guest_os_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific guest OS profile
  microsoft.scvmm.scvmm_guest_os_profile_info:
    name: Win2022-Profile
    vmm_server: scvmm.example.com
  register: profile
'''

RETURN = r'''
guest_os_profiles:
  description: List of guest OS profiles.
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
    computer_name:
      description: Computer name assigned to VMs.
      type: str
      returned: when available
    full_name:
      description: Registered user full name.
      type: str
      returned: when available
    organization_name:
      description: Registered organization name.
      type: str
      returned: when available
    time_zone:
      description: Time zone index.
      type: int
      returned: when available
    domain:
      description: Domain the VM will join.
      type: str
      returned: when available
    domain_join_organizational_unit:
      description: OU for domain join.
      type: str
      returned: when available
    workgroup:
      description: Workgroup name.
      type: str
      returned: when available
    operating_system:
      description: Operating system name.
      type: str
      returned: always
    auto_logon_count:
      description: Auto-logon count.
      type: int
      returned: when available
    shielded:
      description: Whether the profile is shielded.
      type: bool
      returned: always
    linux_domain_name:
      description: DNS domain name for Linux VMs.
      type: str
      returned: when available
    gui_run_once_commands:
      description: Commands to run at first logon.
      type: list
      elements: str
      returned: always
    creation_time:
      description: When the profile was created.
      type: str
      returned: always
'''
