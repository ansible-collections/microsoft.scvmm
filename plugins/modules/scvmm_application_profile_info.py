# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_application_profile_info
version_added: "1.0.0"
short_description: Query application profiles in System Center Virtual Machine Manager
description:
  - Query application profiles from SCVMM.
  - Returns all profiles or a specific profile by name.
options:
  name:
    description:
      - Name of the application profile to query.
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
- name: Get all application profiles
  microsoft.scvmm.scvmm_application_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific application profile
  microsoft.scvmm.scvmm_application_profile_info:
    name: WebApp-Profile
    vmm_server: scvmm.example.com
  register: profile
'''

RETURN = r'''
application_profiles:
  description: List of application profiles.
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
    tag:
      description: Profile tag.
      type: str
      returned: when available
    compatibility_type:
      description: Compatibility type.
      type: str
      returned: always
    creation_time:
      description: When the profile was created.
      type: str
      returned: always
'''
