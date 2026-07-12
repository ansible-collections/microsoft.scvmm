# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_pool_info
short_description: Query storage pools in System Center Virtual Machine Manager
description:
  - Retrieve information about storage pools in SCVMM.
  - Can query all pools or filter by name.
options:
  name:
    description:
      - Name of the storage pool to query.
      - If not specified, returns all storage pools.
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
- name: Get all storage pools
  microsoft.scvmm.scvmm_storage_pool_info:
    vmm_server: scvmm.example.com
  register: all_pools

- name: Get a specific storage pool
  microsoft.scvmm.scvmm_storage_pool_info:
    name: Pool1
    vmm_server: scvmm.example.com
  register: pool_info

- name: Display pool capacity
  ansible.builtin.debug:
    msg: "Pool {{ item.name }}: {{ item.free_capacity_gb }}GB free of {{ item.total_capacity_gb }}GB"
  loop: "{{ all_pools.storage_pools }}"
'''

RETURN = r'''
storage_pools:
  description: List of storage pools.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Storage pool ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Storage pool name.
      type: str
      returned: always
      sample: Pool1
    description:
      description: Storage pool description.
      type: str
      returned: when available
      sample: Primary storage pool
    classification:
      description: Storage classification assigned to the pool.
      type: str
      returned: when available
      sample: Standard
    total_capacity_gb:
      description: Total capacity in GB.
      type: float
      returned: when available
      sample: 1024.0
    free_capacity_gb:
      description: Free capacity in GB.
      type: float
      returned: when available
      sample: 512.0
    is_managed:
      description: Whether the pool is managed by SCVMM.
      type: bool
      returned: always
      sample: true
    enabled:
      description: Whether the pool is enabled.
      type: bool
      returned: always
      sample: true
    health_status:
      description: Health status of the pool.
      type: str
      returned: when available
      sample: OK
'''
