# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_pool
short_description: Manage storage pools in System Center Virtual Machine Manager
description:
  - Assign storage classifications and update descriptions on existing storage pools in SCVMM.
  - Storage pools are discovered from storage providers and cannot be created or deleted through this module.
options:
  name:
    description:
      - Name of the storage pool to manage.
    type: str
    required: true
  storage_classification:
    description:
      - Storage classification to assign to the pool.
    type: str
  description:
    description:
      - Description for the storage pool.
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
- name: Assign classification to storage pool
  microsoft.scvmm.scvmm_storage_pool:
    name: Pool1
    storage_classification: Standard
    vmm_server: scvmm.example.com

- name: Update storage pool description
  microsoft.scvmm.scvmm_storage_pool:
    name: Pool1
    description: Primary production storage
    vmm_server: scvmm.example.com
'''

RETURN = r'''
storage_pool:
  description: Storage pool details after operation.
  returned: always
  type: dict
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
