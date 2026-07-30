# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_user_role
version_added: "1.0.0"
short_description: Manage user roles in System Center Virtual Machine Manager
description:
  - Create, update, or remove user roles in SCVMM.
  - User roles define the scope and permissions for SCVMM users.
  - The O(user_role_profile) parameter is required when creating a new user role and cannot be changed after creation.
options:
  name:
    description:
      - Name of the user role.
    type: str
    required: true
  description:
    description:
      - Description of the user role.
    type: str
  user_role_profile:
    description:
      - Type of user role profile.
      - Required when creating a new user role.
      - Cannot be changed after creation; a warning is emitted if a different value is specified for an existing role.
    type: str
    choices: ['DelegatedAdmin', 'ReadOnlyAdmin', 'SelfServiceUser', 'TenantAdmin']
  state:
    description:
      - Desired state of the user role.
      - V(present) creates or updates a user role.
      - V(absent) removes a user role.
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
- name: Create a delegated admin user role
  microsoft.scvmm.scvmm_user_role:
    name: HelpDeskAdmins
    description: Help desk delegated admin role
    user_role_profile: DelegatedAdmin
    state: present
    vmm_server: scvmm.example.com

- name: Update user role description
  microsoft.scvmm.scvmm_user_role:
    name: HelpDeskAdmins
    description: Updated help desk admin role
    state: present
    vmm_server: scvmm.example.com

- name: Remove a user role
  microsoft.scvmm.scvmm_user_role:
    name: HelpDeskAdmins
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
user_role:
  description: Details of the user role.
  returned: when state is present and user role exists
  type: dict
  contains:
    id:
      description: User role ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: User role name.
      type: str
      returned: always
      sample: "HelpDeskAdmins"
    description:
      description: User role description.
      type: str
      returned: always
      sample: "Help desk delegated admin role"
    user_role_profile:
      description: Type of user role profile.
      type: str
      returned: always
      sample: "DelegatedAdmin"
'''
