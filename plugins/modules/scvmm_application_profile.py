# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_application_profile
short_description: Manage application profiles in System Center Virtual Machine Manager
description:
  - Create, update, and remove application profiles in SCVMM.
  - Application profiles define application deployment settings for VM templates and service templates.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the application profile.
    type: str
    required: true
  description:
    description:
      - Description for the application profile.
    type: str
  owner:
    description:
      - Owner of the profile in DOMAIN\\User format.
    type: str
  tag:
    description:
      - Tag to associate with the profile.
    type: str
  compatibility_type:
    description:
      - The compatibility type of the application profile.
    type: str
    choices: [ General, SQLApplicationHost, WebApplicationHost ]
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
  state:
    description:
      - Desired state of the application profile.
      - C(present) ensures the profile exists.
      - C(absent) ensures the profile is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create an application profile
  microsoft.scvmm.scvmm_application_profile:
    name: WebApp-Profile
    description: Web application deployment profile
    compatibility_type: General
    tag: web
    vmm_server: scvmm.example.com
    state: present

- name: Update profile description
  microsoft.scvmm.scvmm_application_profile:
    name: WebApp-Profile
    description: Updated web application profile
    state: present

- name: Remove an application profile
  microsoft.scvmm.scvmm_application_profile:
    name: WebApp-Profile
    state: absent
'''

RETURN = r'''
application_profile:
  description: Details of the application profile.
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
      sample: WebApp-Profile
    description:
      description: Profile description.
      type: str
      returned: when available
    owner:
      description: Profile owner.
      type: str
      returned: when available
      sample: "DOMAIN\\Admin"
    tag:
      description: Profile tag.
      type: str
      returned: when available
      sample: web
    compatibility_type:
      description: Compatibility type.
      type: str
      returned: always
      sample: General
    creation_time:
      description: When the profile was created.
      type: str
      returned: always
'''
