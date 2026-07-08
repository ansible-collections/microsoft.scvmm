# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_classification
short_description: Manage storage classifications in System Center Virtual Machine Manager
description:
  - Create, update, or remove storage classifications in SCVMM.
  - Uses New-SCStorageClassification to create new classifications.
  - Uses Set-SCStorageClassification to update existing classifications.
  - Uses Remove-SCStorageClassification to delete classifications.
options:
  name:
    description:
      - Name of the storage classification.
    type: str
    required: true
  description:
    description:
      - Description of the storage classification.
    type: str
  state:
    description:
      - Desired state of the storage classification.
      - C(present) creates or updates a classification.
      - C(absent) removes a classification.
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
- name: Create a storage classification
  microsoft.scvmm.scvmm_storage_classification:
    name: Gold
    description: High-performance storage tier
    state: present
    vmm_server: scvmm.example.com

- name: Update classification description
  microsoft.scvmm.scvmm_storage_classification:
    name: Gold
    description: Updated description for gold tier
    state: present
    vmm_server: scvmm.example.com

- name: Remove a storage classification
  microsoft.scvmm.scvmm_storage_classification:
    name: Gold
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
storage_classification:
  description: Details of the storage classification.
  returned: when state is present and classification exists
  type: dict
  contains:
    id:
      description: Storage classification ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Storage classification name.
      type: str
      returned: always
      sample: Gold
    description:
      description: Storage classification description.
      type: str
      returned: when available
      sample: High-performance storage tier
    enabled:
      description: Whether the storage classification is enabled.
      type: bool
      returned: always
      sample: true
    storage_pools:
      description: Names of storage pools assigned to this classification.
      type: list
      elements: str
      returned: always
      sample: []
'''
