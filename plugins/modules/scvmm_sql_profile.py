# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_sql_profile
version_added: "1.0.0"
short_description: Manage SQL profiles in System Center Virtual Machine Manager
description:
  - Create, update, or remove SQL profiles in SCVMM.
  - SQL profiles define SQL Server deployment configurations used by service templates.
options:
  name:
    description:
      - Name of the SQL profile.
    type: str
    required: true
  description:
    description:
      - Description of the SQL profile.
    type: str
  owner:
    description:
      - Owner of the SQL profile.
    type: str
  tag:
    description:
      - Tag for the SQL profile.
    type: str
  state:
    description:
      - Desired state of the SQL profile.
      - C(present) creates or updates a SQL profile.
      - C(absent) removes a SQL profile.
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
- name: Create a SQL profile
  microsoft.scvmm.scvmm_sql_profile:
    name: SQL-Profile-Dev
    description: SQL profile for development
    owner: SCVMM\Administrator
    tag: dev
    state: present
    vmm_server: scvmm.example.com

- name: Update SQL profile description
  microsoft.scvmm.scvmm_sql_profile:
    name: SQL-Profile-Dev
    description: Updated SQL profile for development
    state: present
    vmm_server: scvmm.example.com

- name: Remove a SQL profile
  microsoft.scvmm.scvmm_sql_profile:
    name: SQL-Profile-Dev
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
sql_profile:
  description: Details of the SQL profile.
  returned: when state is present and SQL profile exists
  type: dict
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
