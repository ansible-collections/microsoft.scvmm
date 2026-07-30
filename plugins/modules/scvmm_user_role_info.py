# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_user_role_info
version_added: "1.0.0"
short_description: Query user roles in System Center Virtual Machine Manager
description:
  - Retrieve information about user roles in SCVMM.
  - Can query all user roles or filter by name.
  - User roles define the scope and permissions for SCVMM users.
options:
  name:
    description:
      - Name of the user role to query.
      - If not specified, returns all user roles.
    type: str
  member:
    description:
      - Filter user roles by member account name.
      - Returns only roles that contain this user or group as a member.
      - Use the full account name format, for example V(DOMAIN\\username).
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
- name: Get all user roles
  microsoft.scvmm.scvmm_user_role_info:
    vmm_server: scvmm.example.com
  register: all_roles

- name: Get a specific user role
  microsoft.scvmm.scvmm_user_role_info:
    name: HelpDeskAdmins
    vmm_server: scvmm.example.com
  register: role_info

- name: Get user roles for a specific member
  microsoft.scvmm.scvmm_user_role_info:
    member: DOMAIN\username
    vmm_server: scvmm.example.com
  register: member_roles

- name: Display user roles
  ansible.builtin.debug:
    msg: "{{ item.name }} - {{ item.user_role_profile }}"
  loop: "{{ all_roles.user_roles }}"
'''

RETURN = r'''
user_roles:
  description: List of user roles.
  returned: always
  type: list
  elements: dict
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
    user_role_profile:
      description: Type of user role profile.
      type: str
      returned: always
      sample: "DelegatedAdmin"
'''
