# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_run_as_account_info
version_added: "1.0.0"
short_description: Query Run As accounts in System Center Virtual Machine Manager
description:
  - Retrieve information about Run As accounts in SCVMM.
  - Can query all Run As accounts or filter by name.
  - Run As accounts store credentials used by SCVMM for operations on managed hosts and services.
options:
  name:
    description:
      - Name of the Run As account to query.
      - If not specified, returns all Run As accounts.
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
- name: Get all Run As accounts
  microsoft.scvmm.scvmm_run_as_account_info:
    vmm_server: scvmm.example.com
  register: all_accounts

- name: Get a specific Run As account
  microsoft.scvmm.scvmm_run_as_account_info:
    name: ServiceAccount
    vmm_server: scvmm.example.com
  register: account_info

- name: Display Run As accounts
  ansible.builtin.debug:
    msg: "{{ item.name }} - {{ item.username }}"
  loop: "{{ all_accounts.run_as_accounts }}"
'''

RETURN = r'''
run_as_accounts:
  description: List of Run As accounts.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Run As account ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Run As account name.
      type: str
      returned: always
      sample: "ServiceAccount"
    description:
      description: Run As account description.
      type: str
      returned: always
    username:
      description: Username associated with the Run As account.
      type: str
      returned: always
      sample: "DOMAIN\\svc_account"
'''
