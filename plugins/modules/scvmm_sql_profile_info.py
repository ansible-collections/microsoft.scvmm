# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_sql_profile_info
version_added: "1.0.0"
short_description: Get SQL profile information from System Center Virtual Machine Manager
description:
  - Retrieves information about SQL profiles in SCVMM.
  - Can return details of a specific SQL profile or list all SQL profiles.
options:
  name:
    description:
      - Name of the SQL profile to retrieve.
      - If not specified, returns all SQL profiles.
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
- name: Get all SQL profiles
  microsoft.scvmm.scvmm_sql_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific SQL profile
  microsoft.scvmm.scvmm_sql_profile_info:
    name: SQL-Profile-Dev
    vmm_server: scvmm.example.com
  register: profile_info
'''

RETURN = r'''
sql_profiles:
  description: List of SQL profiles.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: SQL profile ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: SQL profile name.
      type: str
      returned: always
      sample: SQL-Profile-Dev
    description:
      description: SQL profile description.
      type: str
      returned: always
      sample: SQL profile for development
    owner:
      description: Owner of the SQL profile.
      type: str
      returned: always
      sample: SCVMM\Administrator
    tag:
      description: Tag assigned to the SQL profile.
      type: str
      returned: always
      sample: dev
    enabled:
      description: Whether the SQL profile is enabled.
      type: bool
      returned: always
      sample: true
    creation_time:
      description: When the SQL profile was created.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00Z"
    modified_time:
      description: When the SQL profile was last modified.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00Z"
'''
