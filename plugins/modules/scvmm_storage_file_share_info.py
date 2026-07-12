# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_file_share_info
short_description: Query storage file shares in System Center Virtual Machine Manager
description:
  - Retrieve information about storage file shares in SCVMM.
  - Can query all file shares or filter by name.
options:
  name:
    description:
      - Name of the storage file share to query.
      - If not specified, returns all storage file shares.
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
- name: Get all storage file shares
  microsoft.scvmm.scvmm_storage_file_share_info:
    vmm_server: scvmm.example.com
  register: all_shares

- name: Get a specific file share
  microsoft.scvmm.scvmm_storage_file_share_info:
    name: MyFileShare
    vmm_server: scvmm.example.com
  register: share_info

- name: Display file share capacity
  ansible.builtin.debug:
    msg: "Share {{ item.name }} has {{ item.free_capacity_gb }}GB free of {{ item.total_capacity_gb }}GB"
  loop: "{{ all_shares.storage_file_shares }}"
'''

RETURN = r'''
storage_file_shares:
  description: List of storage file shares.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Storage file share ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: File share name.
      type: str
      returned: always
      sample: MyFileShare
    share_path:
      description: UNC path of the file share.
      type: str
      returned: when available
      sample: "\\\\server\\share"
    description:
      description: File share description.
      type: str
      returned: when available
      sample: Primary storage share
    total_capacity_gb:
      description: Total capacity in gigabytes.
      type: float
      returned: when available
      sample: 500.0
    free_capacity_gb:
      description: Free capacity in gigabytes.
      type: float
      returned: when available
      sample: 250.5
    host_access:
      description: Names of VM hosts with access to this share.
      type: list
      elements: str
      returned: always
      sample: ["host1.example.com", "host2.example.com"]
    enabled:
      description: Whether the file share is enabled.
      type: bool
      returned: always
      sample: true
'''
