# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_user_role_quota
version_added: "1.0.0"
short_description: Manage user role quotas in System Center Virtual Machine Manager
description:
  - Configure quotas for user roles in SCVMM.
  - Quotas exist automatically with user roles and cannot be created or deleted independently.
  - This module only updates existing quota settings.
  - Use O(quota_per_user) to distinguish between role-level and member-level quotas.
options:
  user_role_name:
    description:
      - Name of the user role whose quota to manage.
    type: str
    required: true
  quota_per_user:
    description:
      - Whether to manage per-user quotas (member-level) or role-level quotas.
      - V(false) manages the role-level quota.
      - V(true) manages the per-user (member-level) quota.
    type: bool
    default: false
  vm_count:
    description:
      - Maximum number of virtual machines allowed.
    type: int
  cpu_count:
    description:
      - Maximum number of virtual CPUs allowed.
    type: int
  memory_mb:
    description:
      - Maximum memory in megabytes allowed.
    type: int
  storage_gb:
    description:
      - Maximum storage in gigabytes allowed.
    type: int
  custom_quota_count:
    description:
      - Maximum custom quota count allowed.
    type: int
  use_cpu_count_maximum:
    description:
      - Set to V(true) to use unlimited CPU count.
      - This is a write-only parameter; the corresponding count field will be set to null when unlimited.
    type: bool
  use_memory_mb_maximum:
    description:
      - Set to V(true) to use unlimited memory.
      - This is a write-only parameter; the corresponding count field will be set to null when unlimited.
    type: bool
  use_storage_gb_maximum:
    description:
      - Set to V(true) to use unlimited storage.
      - This is a write-only parameter; the corresponding count field will be set to null when unlimited.
    type: bool
  use_custom_quota_count_maximum:
    description:
      - Set to V(true) to use unlimited custom quota count.
      - This is a write-only parameter; the corresponding count field will be set to null when unlimited.
    type: bool
  use_vm_count_maximum:
    description:
      - Set to V(true) to use unlimited VM count.
      - This is a write-only parameter; the corresponding count field will be set to null when unlimited.
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
- name: Set VM count quota for a user role
  microsoft.scvmm.scvmm_user_role_quota:
    user_role_name: HelpDeskAdmins
    vm_count: 10
    cpu_count: 20
    memory_mb: 8192
    storage_gb: 500
    vmm_server: scvmm.example.com

- name: Set per-user quota
  microsoft.scvmm.scvmm_user_role_quota:
    user_role_name: HelpDeskAdmins
    quota_per_user: true
    vm_count: 5
    cpu_count: 10
    vmm_server: scvmm.example.com

- name: Set unlimited VM count
  microsoft.scvmm.scvmm_user_role_quota:
    user_role_name: HelpDeskAdmins
    use_vm_count_maximum: true
    vmm_server: scvmm.example.com
'''

RETURN = r'''
user_role_quota:
  description: Details of the user role quota.
  returned: always
  type: dict
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
      sample: 10
    cpu_count:
      description: Maximum CPU count.
      type: int
      returned: always
      sample: 20
    memory_mb:
      description: Maximum memory in MB.
      type: int
      returned: always
      sample: 8192
    storage_gb:
      description: Maximum storage in GB.
      type: int
      returned: always
      sample: 500
    custom_quota_count:
      description: Maximum custom quota count.
      type: int
      returned: always
      sample: 0
    quota_per_user:
      description: Whether this is a per-user (member-level) quota.
      type: bool
      returned: always
'''
