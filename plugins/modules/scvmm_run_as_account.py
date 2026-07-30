# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_run_as_account
version_added: "1.0.0"
short_description: Manage Run As accounts in System Center Virtual Machine Manager
description:
  - Create, update, or remove Run As accounts in SCVMM.
  - Run As accounts store credentials used by SCVMM to perform operations on managed hosts and services.
  - The O(username) and O(password) parameters are required together when creating or updating credentials.
options:
  name:
    description:
      - Name of the Run As account.
    type: str
    required: true
  description:
    description:
      - Description of the Run As account.
    type: str
  username:
    description:
      - Username for the Run As account credential.
      - Required together with O(password) when creating a new account.
      - When specified for an existing account, the credential is always updated since password changes cannot be detected.
    type: str
  password:
    description:
      - Password for the Run As account credential.
      - Required together with O(username).
      - SCVMM does not expose stored passwords, so changes cannot be detected.
      - See O(update_password) to control when credentials are updated.
    type: str
  update_password:
    description:
      - Controls when the credential is updated on an existing Run As account.
      - V(always) updates the credential every time O(username) and O(password) are provided, even if no other properties changed.
        This always reports C(changed=true) because password comparison is not possible.
      - V(on_create) only sets the credential when creating a new account and ignores it on updates.
    type: str
    choices: ['always', 'on_create']
    default: always
  state:
    description:
      - Desired state of the Run As account.
      - V(present) creates or updates a Run As account.
      - V(absent) removes a Run As account.
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
- name: Create a Run As account
  microsoft.scvmm.scvmm_run_as_account:
    name: ServiceAccount
    description: Service account for automated operations
    username: DOMAIN\\svc_account
    password: "{{ vault_svc_password }}"
    state: present
    vmm_server: scvmm.example.com

- name: Update Run As account description
  microsoft.scvmm.scvmm_run_as_account:
    name: ServiceAccount
    description: Updated service account description
    state: present
    vmm_server: scvmm.example.com

- name: Update Run As account credentials
  microsoft.scvmm.scvmm_run_as_account:
    name: ServiceAccount
    username: DOMAIN\\svc_account
    password: "{{ vault_new_password }}"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a Run As account
  microsoft.scvmm.scvmm_run_as_account:
    name: ServiceAccount
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
run_as_account:
  description: Details of the Run As account.
  returned: when state is present and Run As account exists
  type: dict
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
      returned: when available
      sample: "Service account for automated operations"
    username:
      description: Username associated with the Run As account.
      type: str
      returned: always
      sample: "DOMAIN\\svc_account"
'''
