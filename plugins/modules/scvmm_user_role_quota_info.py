# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_user_role_quota_info
version_added: "1.0.0"
short_description: Query user role quotas in System Center Virtual Machine Manager
description:
  - Retrieve quota information for user roles in SCVMM.
  - Requires a user role name since quotas are associated with user roles.
  - Can filter by O(quota_per_user) to get only role-level or member-level quotas.
options:
  user_role_name:
    description:
      - Name of the user role whose quotas to query.
    type: str
    required: true
  quota_per_user:
    description:
      - Filter quotas by type.
      - V(false) returns only role-level quotas.
      - V(true) returns only per-user (member-level) quotas.
      - If not specified, returns all quotas for the role.
    type: bool
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all quotas for a user role
  microsoft.scvmm.scvmm_user_role_quota_info:
    user_role_name: HelpDeskAdmins
    vmm_server: scvmm.example.com
  register: all_quotas

- name: Get role-level quota only
  microsoft.scvmm.scvmm_user_role_quota_info:
    user_role_name: HelpDeskAdmins
    quota_per_user: false
    vmm_server: scvmm.example.com
  register: role_quota

- name: Display quota details
  ansible.builtin.debug:
    msg: "VM count: {{ role_quota.user_role_quotas[0].vm_count }}"
'''

RETURN = r'''
user_role_quotas:
  description: List of user role quotas.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Quota ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    user_role_name:
      description: Name of the user role this quota belongs to.
      type: str
      returned: always
      sample: "HelpDeskAdmins"
    vm_count:
      description: Maximum VM count.
      type: int
      returned: always
    cpu_count:
      description: Maximum CPU count.
      type: int
      returned: always
    memory_mb:
      description: Maximum memory in MB.
      type: int
      returned: always
    storage_gb:
      description: Maximum storage in GB.
      type: int
      returned: always
    custom_quota_count:
      description: Maximum custom quota count.
      type: int
      returned: always
    quota_per_user:
      description: Whether this is a per-user (member-level) quota.
      type: bool
      returned: always
'''
