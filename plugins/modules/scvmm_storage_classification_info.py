# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_classification_info
short_description: Query storage classifications in System Center Virtual Machine Manager
description:
  - Retrieve information about storage classifications in SCVMM.
  - Can query all classifications or filter by name.
options:
  name:
    description:
      - Name of the storage classification to query.
      - If not specified, returns all storage classifications.
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
- name: Get all storage classifications
  microsoft.scvmm.scvmm_storage_classification_info:
    vmm_server: scvmm.example.com
  register: all_classifications

- name: Get a specific storage classification
  microsoft.scvmm.scvmm_storage_classification_info:
    name: Standard
    vmm_server: scvmm.example.com
  register: classification_info

- name: Display classification details
  ansible.builtin.debug:
    msg: "Classification {{ item.name }} has {{ item.storage_pools | length }} pools"
  loop: "{{ all_classifications.storage_classifications }}"
'''

RETURN = r'''
storage_classifications:
  description: List of storage classifications.
  returned: always
  type: list
  elements: dict
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
      sample: Standard
    description:
      description: Storage classification description.
      type: str
      returned: when available
      sample: Standard storage tier
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
      sample: ["Pool1", "Pool2"]
'''
